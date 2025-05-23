using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using System;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using DailyDietAPI.Model;

namespace DailyDietAPI.Persistence
{
    /// <summary>
    /// Another option is:
    ///     https://alexcodetuts.com/2019/05/22/how-to-seed-users-and-roles-in-asp-net-core/
    /// 
    /// See issues with Startup:
    ///     https://github.com/aspnet/Identity/issues/1458
    ///     https://entityframeworkcore.com/knowledge-base/38704025/cannot-access-a-disposed-object-in-asp-net-core-when-injecting-dbcontext
    ///     
    /// Similar issue with middleware:
    ///     https://stackoverflow.com/questions/39369054/usermanager-dbcontext-already-disposed-in-middleware
    /// </summary>
    public static class MealsDbContextInitializer
    {
        public static async Task Initialize(MealsDbContext context, UserManager<User> userManager, RoleManager<IdentityRole<long>> roleManager)
        {
            context.Database.Migrate();

            if (!context.Users.Any())
            {
                var adminRole = new IdentityRole<long>("Admin");
                var userRole = new IdentityRole<long>("User");

                await roleManager.CreateAsync(adminRole);
                await roleManager.CreateAsync(userRole);

                var adminUser = new User
                {
                    UserName = "admin",
                    Email = "admin@example.com",
                    EmailConfirmed = true,
                    Profile = new UserProfile { AllowedCalories = 2000 }
                };

                var result = await userManager.CreateAsync(adminUser, "Admin123!");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(adminUser, "Admin");
                }

                // Add some sample meals
                var meals = new[]
                {
                    new UserMeals
                    {
                        User = adminUser,
                        Date = DateTime.Now,
                        Description = "Breakfast",
                        Calories = 500
                    },
                    new UserMeals
                    {
                        User = adminUser,
                        Date = DateTime.Now,
                        Description = "Lunch",
                        Calories = 800
                    },
                    new UserMeals
                    {
                        User = adminUser,
                        Date = DateTime.Now,
                        Description = "Dinner",
                        Calories = 700
                    }
                };

                await context.UserMeals.AddRangeAsync(meals);
                await context.SaveChangesAsync();
            }
        }
    }
}
