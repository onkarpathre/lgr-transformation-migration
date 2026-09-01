using System.Text;
using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.Services.Discovery;

public interface IDiscoveryFileReader
{
    Task<DiscoveryFileDocument> ReadAsync(Stream stream, CancellationToken cancellationToken);
}

public sealed class CsvDiscoveryFileReader : IDiscoveryFileReader
{
    public async Task<DiscoveryFileDocument> ReadAsync(Stream stream, CancellationToken cancellationToken)
    {
        try
        {
            using var reader = new StreamReader(stream, new UTF8Encoding(false, true), true, 81920, leaveOpen: true);
            var content = await reader.ReadToEndAsync(cancellationToken);
            return Parse(content);
        }
        catch (DecoderFallbackException)
        {
            throw new DomainValidationException("The discovery file must be valid UTF-8 text.");
        }
    }

    public DiscoveryFileDocument Parse(string content)
    {
        if (string.IsNullOrWhiteSpace(content)) throw new DomainValidationException("The discovery file is empty.");

        var rows = ParseRows(content);
        if (rows.Count == 0) throw new DomainValidationException("The discovery file does not contain a header row.");

        var headers = rows[0].Select((value, index) =>
        {
            var header = index == 0 ? value.Trim().TrimStart('\uFEFF') : value.Trim();
            if (string.IsNullOrWhiteSpace(header)) throw new DomainValidationException($"Header column {index + 1} is blank.");
            return header;
        }).ToArray();

        var mappedRows = new List<CsvDataRow>();
        for (var index = 1; index < rows.Count; index++)
        {
            var values = rows[index];
            if (values.All(string.IsNullOrWhiteSpace)) continue;
            if (values.Count > headers.Length)
                throw new DomainValidationException($"CSV row {index + 1} contains more values than the header row.");

            var raw = new Dictionary<string, string>(StringComparer.Ordinal);
            for (var column = 0; column < headers.Length; column++)
                raw[headers[column]] = column < values.Count ? values[column].Trim() : string.Empty;
            mappedRows.Add(new CsvDataRow(index + 1, raw));
        }

        return new DiscoveryFileDocument(headers, mappedRows);
    }

    private static List<List<string>> ParseRows(string content)
    {
        var rows = new List<List<string>>();
        var row = new List<string>();
        var field = new StringBuilder();
        var inQuotes = false;
        var fieldStarted = false;

        for (var index = 0; index < content.Length; index++)
        {
            var current = content[index];
            if (inQuotes)
            {
                if (current == '"')
                {
                    if (index + 1 < content.Length && content[index + 1] == '"')
                    {
                        field.Append('"');
                        index++;
                    }
                    else
                    {
                        inQuotes = false;
                    }
                }
                else
                {
                    field.Append(current);
                }
                continue;
            }

            switch (current)
            {
                case '"':
                    if (fieldStarted || field.Length > 0) throw new DomainValidationException("The CSV contains a quote in an unquoted field.");
                    inQuotes = true;
                    fieldStarted = true;
                    break;
                case ',':
                    row.Add(field.ToString());
                    field.Clear();
                    fieldStarted = false;
                    break;
                case '\r':
                case '\n':
                    if (current == '\r' && index + 1 < content.Length && content[index + 1] == '\n') index++;
                    row.Add(field.ToString());
                    field.Clear();
                    fieldStarted = false;
                    rows.Add(row);
                    row = [];
                    break;
                default:
                    field.Append(current);
                    fieldStarted = true;
                    break;
            }
        }

        if (inQuotes) throw new DomainValidationException("The CSV contains an unterminated quoted field.");
        if (row.Count > 0 || field.Length > 0 || fieldStarted)
        {
            row.Add(field.ToString());
            rows.Add(row);
        }
        return rows;
    }
}
