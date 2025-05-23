using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using DailyDietAPI.Model;

namespace DailyDietAPI.Persistence.Mapping
{
    public class UserMealMap : IEntityTypeConfiguration<UserMeals>
    {
        public void Configure(EntityTypeBuilder<UserMeals> builder)
        {
            builder.HasKey(x => x.Id);
            
            builder.HasOne(x => x.User)
                .WithMany(u => u.Meals)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade)
                .IsRequired();
        }
    }
}
