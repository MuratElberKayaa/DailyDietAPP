using System.Collections.Generic;
using System.Threading.Tasks;
using DailyDietAPI.Model;

namespace DailyDietAPI.Services.Repositories
{
    public interface IMealRepository
    {
        Task<IEnumerable<Meal>> GetAllAsync();
        Task<Meal> GetByIdAsync(int id);
        Task<Meal> AddAsync(Meal meal);
        Task<Meal> UpdateAsync(Meal meal);
        Task DeleteAsync(int id);
    }
} 