using System.Security.Cryptography;
using System.Net.Http.Headers;
using System.Xml.Linq;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.Extensions.Options;

namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed record StoredImportFile(string StoredFileName, string FileHash, long FileSizeBytes);

public interface IImportFileStorage
{
    Task<StoredImportFile> SaveAsync(Stream source, string extension, long maximumBytes, CancellationToken cancellationToken);
    Task<Stream> OpenReadAsync(string storedFileName, CancellationToken cancellationToken);
    Task DeleteAsync(string storedFileName, CancellationToken cancellationToken);
}

public interface IImportStorageReadiness
{
    ValueTask<bool> IsReadyAsync(CancellationToken cancellationToken);
}

public sealed class LocalImportFileStorage : IImportFileStorage, IImportStorageReadiness
{
    private readonly string rootPath;

    public LocalImportFileStorage(IOptions<DiscoveryImportOptions> options, IWebHostEnvironment environment)
    {
        var configured = options.Value.LocalStoragePath;
        rootPath = Path.GetFullPath(Path.IsPathRooted(configured)
            ? configured
            : Path.Combine(environment.ContentRootPath, configured));
        Directory.CreateDirectory(rootPath);
    }

    public async Task<StoredImportFile> SaveAsync(Stream source, string extension, long maximumBytes, CancellationToken cancellationToken)
    {
        if (maximumBytes <= 0) throw new InvalidOperationException("The discovery import file-size limit must be positive.");

        var safeExtension = extension.ToLowerInvariant();
        if (safeExtension != ".csv") throw new Domain.DomainValidationException("Only UTF-8 CSV files are supported in Phase 2.");

        var storedFileName = $"{Guid.NewGuid():N}{safeExtension}";
        var path = Resolve(storedFileName);
        long size = 0;
        using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);

        try
        {
            await using var destination = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, FileOptions.Asynchronous);
            var buffer = new byte[81920];
            while (true)
            {
                var read = await source.ReadAsync(buffer, cancellationToken);
                if (read == 0) break;
                size += read;
                if (size > maximumBytes) throw new Domain.DomainValidationException($"The upload exceeds the configured {maximumBytes} byte limit.");
                hash.AppendData(buffer, 0, read);
                await destination.WriteAsync(buffer.AsMemory(0, read), cancellationToken);
            }

            if (size == 0) throw new Domain.DomainValidationException("The uploaded file is empty.");
            return new StoredImportFile(storedFileName, Convert.ToHexString(hash.GetHashAndReset()).ToLowerInvariant(), size);
        }
        catch
        {
            if (File.Exists(path)) File.Delete(path);
            throw;
        }
    }

    public Task<Stream> OpenReadAsync(string storedFileName, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        Stream stream = new FileStream(Resolve(storedFileName), FileMode.Open, FileAccess.Read, FileShare.Read, 81920, FileOptions.Asynchronous | FileOptions.SequentialScan);
        return Task.FromResult(stream);
    }

    public Task DeleteAsync(string storedFileName, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var path = Resolve(storedFileName);
        if (File.Exists(path)) File.Delete(path);
        return Task.CompletedTask;
    }

    private string Resolve(string storedFileName)
    {
        if (string.IsNullOrWhiteSpace(storedFileName) || Path.GetFileName(storedFileName) != storedFileName)
            throw new Domain.DomainValidationException("The stored import filename is invalid.");

        var path = Path.GetFullPath(Path.Combine(rootPath, storedFileName));
        if (!path.StartsWith(rootPath + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
            throw new Domain.DomainValidationException("The stored import path is invalid.");
        return path;
    }

    public ValueTask<bool> IsReadyAsync(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return ValueTask.FromResult(Directory.Exists(rootPath));
    }
}

public sealed class AzureBlobImportFileStorage(
    IOptions<DiscoveryImportOptions> options,
    ICurrentCustomerContext customerContext,
    IHttpClientFactory httpClientFactory,
    IAzureAccessTokenProvider tokenProvider,
    TimeProvider timeProvider,
    ILogger<AzureBlobImportFileStorage> logger) : IImportFileStorage, IImportStorageReadiness
{
    private const string StorageScope = "https://storage.azure.com/.default";
    private const string ApiVersion = "2023-11-03";
    private readonly DiscoveryImportOptions settings = options.Value;

    public async Task<StoredImportFile> SaveAsync(
        Stream source,
        string extension,
        long maximumBytes,
        CancellationToken cancellationToken)
    {
        if (!string.Equals(extension, ".csv", StringComparison.OrdinalIgnoreCase))
        {
            throw new Domain.DomainValidationException("Only UTF-8 CSV files are supported in Phase 2.");
        }

        await using var buffer = new MemoryStream();
        using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        var block = new byte[81920];
        long size = 0;
        while (true)
        {
            var read = await source.ReadAsync(block, cancellationToken);
            if (read == 0) break;
            size += read;
            if (size > maximumBytes)
            {
                throw new Domain.DomainValidationException($"The upload exceeds the configured {maximumBytes} byte limit.");
            }

            hash.AppendData(block, 0, read);
            await buffer.WriteAsync(block.AsMemory(0, read), cancellationToken);
        }

        if (size == 0)
        {
            throw new Domain.DomainValidationException("The uploaded file is empty.");
        }

        var storedFileName = string.Join('/',
            customerContext.CustomerId.ToString("D"),
            customerContext.ProjectId.ToString("D"),
            Guid.NewGuid().ToString("N"),
            $"{Guid.NewGuid():N}.csv");
        buffer.Position = 0;
        using var request = await CreateRequestAsync(HttpMethod.Put, BlobUri(storedFileName), cancellationToken);
        request.Headers.Add("x-ms-blob-type", "BlockBlob");
        request.Headers.Add("x-ms-meta-data-classification", "synthetic");
        request.Headers.Add("x-ms-meta-scan-disposition", "pending");
        request.Content = new StreamContent(buffer);
        request.Content.Headers.ContentType = new MediaTypeHeaderValue("text/csv") { CharSet = "utf-8" };
        request.Content.Headers.ContentLength = size;
        using var response = await Client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        response.EnsureSuccessStatusCode();

        try
        {
            await WaitForCleanScanAsync(storedFileName, cancellationToken);
        }
        catch
        {
            await DeleteAsync(storedFileName, cancellationToken);
            throw;
        }

        return new StoredImportFile(
            storedFileName,
            Convert.ToHexString(hash.GetHashAndReset()).ToLowerInvariant(),
            size);
    }

    public async Task<Stream> OpenReadAsync(string storedFileName, CancellationToken cancellationToken)
    {
        ValidateObjectName(storedFileName);
        await WaitForCleanScanAsync(storedFileName, cancellationToken);
        using var request = await CreateRequestAsync(HttpMethod.Get, BlobUri(storedFileName), cancellationToken);
        var response = await Client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        try
        {
            response.EnsureSuccessStatusCode();
            return new ResponseOwnedStream(
                await response.Content.ReadAsStreamAsync(cancellationToken),
                response);
        }
        catch
        {
            response.Dispose();
            throw;
        }
    }

    public async Task DeleteAsync(string storedFileName, CancellationToken cancellationToken)
    {
        ValidateObjectName(storedFileName);
        using var request = await CreateRequestAsync(HttpMethod.Delete, BlobUri(storedFileName), cancellationToken);
        request.Headers.Add("x-ms-delete-snapshots", "include");
        using var response = await Client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        if (response.StatusCode != System.Net.HttpStatusCode.NotFound)
        {
            response.EnsureSuccessStatusCode();
        }
    }

    public async ValueTask<bool> IsReadyAsync(CancellationToken cancellationToken)
    {
        try
        {
            using var request = await CreateRequestAsync(HttpMethod.Get, ContainerUri("restype=container&comp=list&maxresults=1"), cancellationToken);
            using var response = await Client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            if (response.IsSuccessStatusCode)
            {
                return true;
            }

            AzureDemoDependencyDiagnostics.LogFalse(logger, "storage", response.StatusCode);
            return false;
        }
        catch (Exception exception) when (!cancellationToken.IsCancellationRequested)
        {
            if (AzureDemoDependencyDiagnostics.IsTimeout(exception))
            {
                AzureDemoDependencyDiagnostics.LogTimeout(
                    logger,
                    "storage",
                    exception,
                    "dependency-timeout");
            }
            else
            {
                AzureDemoDependencyDiagnostics.LogException(
                    logger,
                    "storage",
                    exception,
                    "dependency-exception");
            }
            return false;
        }
    }

    private async Task WaitForCleanScanAsync(string storedFileName, CancellationToken cancellationToken)
    {
        var deadline = timeProvider.GetUtcNow().AddSeconds(Math.Clamp(settings.MalwareScanTimeoutSeconds, 1, 600));
        while (timeProvider.GetUtcNow() < deadline)
        {
            using var request = await CreateRequestAsync(HttpMethod.Get, BlobUri(storedFileName, "comp=tags"), cancellationToken);
            using var response = await Client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            response.EnsureSuccessStatusCode();
            var xml = XDocument.Load(await response.Content.ReadAsStreamAsync(cancellationToken));
            var tags = xml.Descendants("Tag").ToDictionary(
                element => element.Element("Key")?.Value ?? string.Empty,
                element => element.Element("Value")?.Value ?? string.Empty,
                StringComparer.OrdinalIgnoreCase);
            if (tags.TryGetValue("Malware Scanning scan result", out var result))
            {
                if (string.Equals(result, "No threats found", StringComparison.OrdinalIgnoreCase))
                {
                    return;
                }

                if (!string.Equals(result, "Not scanned", StringComparison.OrdinalIgnoreCase))
                {
                    throw new Domain.DomainValidationException("The uploaded file did not pass the required security scan.");
                }
            }

            await Task.Delay(TimeSpan.FromSeconds(Math.Clamp(settings.MalwareScanPollSeconds, 1, 10)), cancellationToken);
        }

        throw new Domain.DomainValidationException("The uploaded file security scan did not complete within the allowed time.");
    }

    private HttpClient Client => httpClientFactory.CreateClient("AzurePrivateDataPlane");

    private async Task<HttpRequestMessage> CreateRequestAsync(HttpMethod method, Uri uri, CancellationToken cancellationToken)
    {
        var request = new HttpRequestMessage(method, uri);
        request.Headers.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            await tokenProvider.GetTokenAsync(StorageScope, cancellationToken));
        request.Headers.Add("x-ms-version", ApiVersion);
        request.Headers.Add("x-ms-date", DateTimeOffset.UtcNow.ToString("R"));
        return request;
    }

    private Uri ContainerUri(string? query = null)
    {
        return new UriBuilder(new Uri(AccountUri(), Uri.EscapeDataString(settings.ContainerName)))
        {
            Query = query ?? string.Empty
        }.Uri;
    }

    private Uri BlobUri(string storedFileName, string? query = null)
    {
        ValidateObjectName(storedFileName);
        var escaped = string.Join('/', storedFileName.Split('/').Select(Uri.EscapeDataString));
        return new UriBuilder(new Uri(AccountUri(), $"{Uri.EscapeDataString(settings.ContainerName)}/{escaped}"))
        {
            Query = query ?? string.Empty
        }.Uri;
    }

    private Uri AccountUri() => new(settings.StorageAccountUri.TrimEnd('/') + "/", UriKind.Absolute);

    private void ValidateObjectName(string storedFileName)
    {
        var expectedPrefix = $"{customerContext.CustomerId:D}/{customerContext.ProjectId:D}/";
        if (string.IsNullOrWhiteSpace(storedFileName)
            || storedFileName.Contains("..", StringComparison.Ordinal)
            || storedFileName.Contains('\\')
            || !storedFileName.StartsWith(expectedPrefix, StringComparison.Ordinal))
        {
            throw new Domain.DomainValidationException("The stored import object name is invalid.");
        }
    }

    private sealed class ResponseOwnedStream(Stream inner, HttpResponseMessage response) : Stream
    {
        public override bool CanRead => inner.CanRead;
        public override bool CanSeek => inner.CanSeek;
        public override bool CanWrite => false;
        public override long Length => inner.Length;
        public override long Position { get => inner.Position; set => inner.Position = value; }
        public override void Flush() => inner.Flush();
        public override int Read(byte[] buffer, int offset, int count) => inner.Read(buffer, offset, count);
        public override long Seek(long offset, SeekOrigin origin) => inner.Seek(offset, origin);
        public override void SetLength(long value) => throw new NotSupportedException();
        public override void Write(byte[] buffer, int offset, int count) => throw new NotSupportedException();
        public override async ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default) =>
            await inner.ReadAsync(buffer, cancellationToken);
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                inner.Dispose();
                response.Dispose();
            }
            base.Dispose(disposing);
        }
        public override async ValueTask DisposeAsync()
        {
            await inner.DisposeAsync();
            response.Dispose();
            GC.SuppressFinalize(this);
        }
    }
}
