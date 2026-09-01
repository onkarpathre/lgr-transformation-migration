using System.Security.Cryptography;
using Microsoft.Extensions.Options;

namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed record StoredImportFile(string StoredFileName, string FileHash, long FileSizeBytes);

public interface IImportFileStorage
{
    Task<StoredImportFile> SaveAsync(Stream source, string extension, long maximumBytes, CancellationToken cancellationToken);
    Task<Stream> OpenReadAsync(string storedFileName, CancellationToken cancellationToken);
    Task DeleteAsync(string storedFileName, CancellationToken cancellationToken);
}

public sealed class LocalImportFileStorage : IImportFileStorage
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
}
