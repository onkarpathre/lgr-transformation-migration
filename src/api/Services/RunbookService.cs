using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.Services;

public sealed class RunbookService(AppDbContext db, ICurrentCustomerContext context, TimeProvider timeProvider)
{
    public async Task<RunbookDto> GenerateAsync(GenerateRunbookRequest request, CancellationToken cancellationToken)
    {
        var wave = await db.MigrationWaves.SingleOrDefaultAsync(
            x => x.Id == request.MigrationWaveId && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Migration wave not found.");

        var exists = await db.Runbooks.AnyAsync(x => x.MigrationWaveId == wave.Id, cancellationToken);
        if (exists)
        {
            throw new DomainValidationException("A runbook already exists for this migration wave.");
        }

        var now = timeProvider.GetUtcNow();
        var runbook = new Runbook
        {
            Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId,
            MigrationWaveId = wave.Id, Name = string.IsNullOrWhiteSpace(request.Name) ? $"{wave.Name} Migration Runbook" : request.Name.Trim(),
            Status = "Draft", CreatedAt = now, UpdatedAt = now
        };
        runbook.Tasks = RunbookTemplate.DefaultTasks.Select((task, index) => new RunbookTask
        {
            Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId,
            Sequence = index + 1, Category = task, Task = task, Owner = "Unassigned", Status = "Not Started", Comment = string.Empty
        }).ToList();

        db.Runbooks.Add(runbook);
        await db.SaveChangesAsync(cancellationToken);
        return await GetAsync(runbook.Id, cancellationToken);
    }

    public async Task<IReadOnlyList<RunbookDto>> ListAsync(CancellationToken cancellationToken)
    {
        var ids = await db.Runbooks.Where(x => x.ProjectId == context.ProjectId).OrderBy(x => x.Name).Select(x => x.Id).ToListAsync(cancellationToken);
        var result = new List<RunbookDto>();
        foreach (var id in ids)
        {
            result.Add(await GetAsync(id, cancellationToken));
        }
        return result;
    }

    public async Task<RunbookDto> GetAsync(Guid id, CancellationToken cancellationToken)
    {
        return await db.Runbooks.Where(x => x.Id == id && x.ProjectId == context.ProjectId)
            .Select(x => new RunbookDto(
                x.Id, x.MigrationWaveId, x.MigrationWave.Name, x.Name, x.Status,
                x.Tasks.OrderBy(t => t.Sequence).Select(t => new RunbookTaskDto(
                    t.Id, t.Sequence, t.Category, t.Task, t.Owner, t.PlannedStart, t.PlannedEnd,
                    t.ActualStart, t.ActualEnd, t.Status, t.Comment)).ToList(),
                x.CreatedAt, x.UpdatedAt))
            .SingleOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("Runbook not found.");
    }

    public async Task<RunbookDto> UpdateTaskAsync(Guid runbookId, Guid taskId, RunbookTaskUpdateRequest request, CancellationToken cancellationToken)
    {
        var task = await db.RunbookTasks.SingleOrDefaultAsync(
            x => x.Id == taskId && x.RunbookId == runbookId && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Runbook task not found.");

        task.Status = request.Status;
        task.Owner = request.Owner ?? task.Owner;
        task.Comment = request.Comment ?? task.Comment;
        task.ActualStart = request.ActualStart;
        task.ActualEnd = request.ActualEnd;
        var runbook = await db.Runbooks.SingleAsync(x => x.Id == runbookId, cancellationToken);
        runbook.UpdatedAt = timeProvider.GetUtcNow();
        await db.SaveChangesAsync(cancellationToken);
        return await GetAsync(runbookId, cancellationToken);
    }
}
