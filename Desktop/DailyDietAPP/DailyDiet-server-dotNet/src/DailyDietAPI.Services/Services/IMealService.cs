using System.Collections.Generic;
using System.Threading.Tasks;
using DailyDietAPI.Model;

namespace DailyDietAPI.Services
{
    public interface IMealService
    {
        Task<IEnumerable<Meal>> GetAllMealsAsync();
        Task<Meal> GetMealByIdAsync(int id);
        Task<Meal> CreateMealAsync(Meal meal);
        Task<Meal> UpdateMealAsync(Meal meal);
        Task DeleteMealAsync(int id);
    }
} 