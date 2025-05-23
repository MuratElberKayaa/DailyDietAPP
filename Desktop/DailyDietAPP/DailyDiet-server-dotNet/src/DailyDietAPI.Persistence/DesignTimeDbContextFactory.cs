using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;

namespace DailyDietAPI.Persistence
{
    public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<MealsDbContext>
    {
        public MealsDbContext CreateDbContext(string[] args)
        {
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json")
                .Build();

            var builder = new DbContextOptionsBuilder<MealsDbContext>();
            var connectionString = configuration.GetConnectionString("DefaultConnection");

            builder.UseNpgsql(connectionString, x => 
            {
                x.MigrationsAssembly("DailyDietAPI.Persistence");
                x.EnableRetryOnFailure(3);
            });

            return new MealsDbContext(builder.Options, configuration);
        }
    }
} 