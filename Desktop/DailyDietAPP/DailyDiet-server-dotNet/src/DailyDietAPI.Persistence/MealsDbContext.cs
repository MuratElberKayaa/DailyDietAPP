using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using DailyDietAPI.Persistence.Mapping;
using DailyDietAPI.Model;
using System;
using DailyDietAPI.Persistence;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace DailyDietAPI.Persistence
{
    public class MealsDbContext : IdentityDbContext<User, IdentityRole<long>, long>
    {
        private readonly IConfiguration? _configuration;

        public DbSet<UserMeals> UserMeals { get; set; } = null!;
        public DbSet<UserProfile> UserProfiles { get; set; } = null!;
        public DbSet<Meal> Meals { get; set; } = null!;
        public DbSet<DietPlan> DietPlans { get; set; } = null!;

        public MealsDbContext(DbContextOptions<MealsDbContext> options, IConfiguration? configuration = null)
            : base(options)
        {
            _configuration = configuration;
        }

        public void Reload<TEntity>(TEntity entity) where TEntity : class
        {
            Entry(entity).Reload();
        }
        
        public Task ReloadAsync<TEntity>(TEntity entity) where TEntity : class
        {
            return Entry(entity).ReloadAsync();
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                if (_configuration != null)
                {
                    var connectionString = _configuration.GetConnectionString("DefaultConnection");
                    optionsBuilder.UseNpgsql(connectionString, x => 
                    {
                        x.MigrationsAssembly("DailyDietAPI.Persistence");
                        x.EnableRetryOnFailure(3);
                    });
                }
            }
            base.OnConfiguring(optionsBuilder);
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Identity tables
            modelBuilder.Entity<User>().ToTable("Users");
            modelBuilder.Entity<IdentityRole<long>>().ToTable("Roles");
            modelBuilder.Entity<IdentityUserRole<long>>().ToTable("UserRoles");
            modelBuilder.Entity<IdentityUserClaim<long>>().ToTable("UserClaims");
            modelBuilder.Entity<IdentityUserLogin<long>>().ToTable("UserLogins");
            modelBuilder.Entity<IdentityRoleClaim<long>>().ToTable("RoleClaims");
            modelBuilder.Entity<IdentityUserToken<long>>().ToTable("UserTokens");

            // Configure entity relationships
            modelBuilder.ConfigureUser();
            modelBuilder.ConfigureUserProfile();
            modelBuilder.ConfigureUserMeals();
            modelBuilder.ConfigureDietPlan();

            // Register all entity configurations
            modelBuilder.RegisterMappingsInsideNamespace<IMappingContainer>();
        }
    }
}
