using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using DailyDietAPI.Model;

namespace DailyDietAPI.Persistence.Mapping
{
    public static class MealMap
    {
        public static void ConfigureMeal(this ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Meal>(entity =>
            {
                entity.ToTable("Meals");
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).HasMaxLength(100);
                entity.Property(e => e.Description).HasMaxLength(500);
                entity.Property(e => e.MealTime).IsRequired();
                entity.Property(e => e.Calories).IsRequired();
                entity.Property(e => e.UserId).IsRequired(false);
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.SetNull);
            });
        }
    }
} 