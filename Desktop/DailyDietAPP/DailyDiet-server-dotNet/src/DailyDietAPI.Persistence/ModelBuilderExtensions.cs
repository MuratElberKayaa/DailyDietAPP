using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using DailyDietAPI.Model;

namespace DailyDietAPI.Persistence
{
    public static class ModelBuilderExtensions
    {
        public delegate bool MappingFilterDelegate(Type mappingClass, Type entity);

        public static void RegisterMappingsFrom<TAssembly>(this ModelBuilder modelBuilder, MappingFilterDelegate filter = null)
        {
            var mappingsAssembly = typeof(TAssembly);

            var q =
                from type in mappingsAssembly.Assembly.GetTypes()
                from @interface in type.GetInterfaces().Where(i => i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IEntityTypeConfiguration<>))
                let classType = type
                let entityType = @interface.GetGenericArguments()[0]
                where filter == null || filter(classType, entityType)
                select type;

            var entityTypeConfigurationTypesToRegister = q.Distinct().ToList();

            foreach (var entityTypeconfigurationType in entityTypeConfigurationTypesToRegister)
            {
                dynamic configurationInstance = Activator.CreateInstance(entityTypeconfigurationType);
                modelBuilder.ApplyConfiguration(configurationInstance);
            }
        }

        public static void RegisterMappingsInsideNamespace<TMapMarker>(this ModelBuilder modelBuilder, MappingFilterDelegate filter = null)
        {
            var mappingMarker = typeof(TMapMarker);
            var mappingMarkerNS = mappingMarker.Namespace;

            RegisterMappingsFrom<TMapMarker>(modelBuilder, (classType, entityType) =>
            {
                // make sure we're inside the desired namespace
                if (!classType.FullName.StartsWith(mappingMarkerNS + "."))
                    return false;

                // do additional custom filter logic
                return filter == null || filter(classType, entityType);
            });
        }

        public static void ConfigureUser(this ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>(entity =>
            {
                entity.ToTable("Users");
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Email).HasMaxLength(256);
                entity.Property(e => e.NormalizedEmail).HasMaxLength(256);
                entity.Property(e => e.UserName).HasMaxLength(256);
                entity.Property(e => e.NormalizedUserName).HasMaxLength(256);
            });
        }

        public static void ConfigureUserProfile(this ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<UserProfile>(entity =>
            {
                entity.ToTable("UserProfiles");
                entity.HasKey(e => e.Id);
                entity.Property(e => e.UserId).IsRequired();
                entity.HasOne(e => e.User)
                    .WithOne(u => u.Profile)
                    .HasForeignKey<UserProfile>(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        public static void ConfigureUserMeals(this ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<UserMeals>(entity =>
            {
                entity.ToTable("UserMeals");
                entity.HasKey(e => e.Id);
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Meals)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        public static void ConfigureDietPlan(this ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DietPlan>(entity =>
            {
                entity.ToTable("DietPlans");
                entity.HasKey(e => e.Id);
                entity.Property(e => e.UserId).IsRequired();
                entity.Property(e => e.Plan).IsRequired();
                entity.Property(e => e.CreatedAt).IsRequired();
            });
        }
    }
}
