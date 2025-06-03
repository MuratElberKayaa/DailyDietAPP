using System;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using DailyDietAPI.Persistence;
using Microsoft.AspNetCore.Identity;
using DailyDietAPI.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using DailyDietAPI.Services;
using System.Threading.Tasks;

namespace DailyDietAPI
{
    public class Program
    {
        /// <summary>
        /// https://github.com/aspnet/AspNetCore/blob/master/src/Hosting/Abstractions/src/WebHostDefaults.cs
        /// </summary>
        /// <param name="args"></param>
        public static async Task Main(string[] args)
        {
            try
            {
                AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);
                var host = CreateHostBuilder(args).Build();
                
                // Veritabanı bağlantısını test et ve admin/rolleri ekle
                using (var scope = host.Services.CreateScope())
                {
                    var services = scope.ServiceProvider;
                    try
                    {
                        var context = services.GetRequiredService<MealsDbContext>();
                        var userManager = services.GetRequiredService<UserManager<User>>();
                        var roleManager = services.GetRequiredService<RoleManager<IdentityRole<long>>>();
                        await MealsDbContextInitializer.Initialize(context, userManager, roleManager);
                        context.Database.CanConnect();
                    }
                    catch (Exception ex)
                    {
                        var logger = services.GetRequiredService<ILogger<Program>>();
                        logger.LogError(ex, "An error occurred while seeding the database.");
                        throw;
                    }
                }

                host.Run();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Uygulama başlatılırken hata oluştu: {ex}");
                Console.WriteLine($"Stack Trace: {ex.StackTrace}");
                throw;
            }
        }

        /// <summary>
        /// --environment "Test" vs .UseEnvironment("Test")
        /// </summary>
        /// <param name="args"></param>
        /// <returns></returns>
        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureLogging((hostContext, logging) => {
                    logging.ClearProviders();
                    logging.AddConsole();
                    logging.AddDebug();
                    logging.AddEventSourceLogger();
                    
                    // Tüm log seviyelerini göster
                    logging.SetMinimumLevel(LogLevel.Trace);
                    
                    if (hostContext.HostingEnvironment.IsDevelopment())
                    {
                        logging.AddDebug();
                        logging.SetMinimumLevel(LogLevel.Debug);
                    }
                })
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                    // Railway.com için port ayarı
                    var port = Environment.GetEnvironmentVariable("PORT") ?? "5000";
                    webBuilder.UseUrls($"http://0.0.0.0:{port}");
                });
    }
}

/*
 * https://docs.microsoft.com/en-us/aspnet/core/fundamentals/host/generic-host?view=aspnetcore-3.0
 * https://andrewlock.net/how-to-use-multiple-hosting-environments-on-the-same-machine-in-asp-net-core/
 */
