using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services;
using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentCustomerContext, CurrentCustomerContext>();
builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlServer(
    builder.Configuration.GetConnectionString("LgrDatabase")
    ?? throw new InvalidOperationException("ConnectionStrings:LgrDatabase is required.")));
builder.Services.AddScoped<ProgrammeService>();
builder.Services.AddScoped<SqlInventoryService>();
builder.Services.AddScoped<IpAllocationService>();
builder.Services.AddScoped<RunbookService>();
builder.Services.Configure<DiscoveryImportOptions>(builder.Configuration.GetSection(DiscoveryImportOptions.SectionName));
var discoveryOptions = builder.Configuration.GetSection(DiscoveryImportOptions.SectionName).Get<DiscoveryImportOptions>() ?? new();
builder.Services.Configure<FormOptions>(form => form.MultipartBodyLengthLimit = discoveryOptions.MaximumFileSizeBytes + 65536);
builder.Services.AddSingleton<IImportFileStorage, LocalImportFileStorage>();
builder.Services.AddSingleton<IDiscoveryFileReader, CsvDiscoveryFileReader>();
builder.Services.AddSingleton<IDiscoverySourceMapper, AzureMigrateServerReportMapper>();
builder.Services.AddSingleton<IDiscoverySourceMapper, AzureMigrateAllInventoryMapper>();
builder.Services.AddSingleton<DiscoverySourceMapperResolver>();
builder.Services.AddSingleton<DiscoveryRecordValidator>();
builder.Services.AddSingleton<DiscoveryReconciler>();
builder.Services.AddScoped<DiscoveryImportService>();
builder.Services.AddSingleton<ReadinessCalculator>();
builder.Services.AddSingleton<IpTransitionPolicy>();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddProblemDetails();
builder.Services.Configure<FeatureOptions>(builder.Configuration.GetSection(FeatureOptions.SectionName));
builder.Services.AddScoped<SqlDiscoveryAssessmentFeatureFilter>();
builder.Services.AddControllers().ConfigureApiBehaviorOptions(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var problemDetails = new ValidationProblemDetails(context.ModelState)
        {
            Type = "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.1",
            Title = "Request validation failed",
            Status = StatusCodes.Status400BadRequest,
            Detail = "One or more request fields are invalid.",
            Instance = context.HttpContext.Request.Path
        };
        problemDetails.Extensions["errorCode"] = "validation_failed";
        problemDetails.Extensions["correlationId"] = context.HttpContext.TraceIdentifier;

        return new BadRequestObjectResult(problemDetails)
        {
            ContentTypes = { "application/problem+json" }
        };
    };
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new() { Title = "LGR Transformation and Migration API", Version = "v1" });
});

var origins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? ["http://localhost:3000"];
builder.Services.AddCors(options => options.AddPolicy("Web", policy => policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

app.UseExceptionHandler();
app.UseCors("Web");
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "Healthy" })).ExcludeFromDescription();

app.Run();

public partial class Program;
