using DOGO2.Components;
using DOGO2.Data;
using Microsoft.EntityFrameworkCore;
using Syncfusion.Blazor;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContextFactory<DOGO2Context>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DOGO2Context") ?? throw new InvalidOperationException("Connection string 'DOGO2Context' not found.")));

builder.Services.AddQuickGridEntityFrameworkAdapter();

builder.Services.AddDatabaseDeveloperPageExceptionFilter();


// Add services to the container.

builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddSyncfusionBlazor(options => { /* options.IgnoreScriptIsolation = true; */ });

//builder.Services.AddSyncfusionBlazor();

var app = builder.Build();

Syncfusion.Licensing.SyncfusionLicenseProvider.RegisterLicense("MzkxMDE0OUAzMjM5MmUzMDJlMzAzYjMyMzkzYlhDNVFKa05GQkcwRGIxVjdzVWFRM3p0SU84TWYvMUJiLzZDNnlaN3FpS3c9");

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
    app.UseMigrationsEndPoint();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
