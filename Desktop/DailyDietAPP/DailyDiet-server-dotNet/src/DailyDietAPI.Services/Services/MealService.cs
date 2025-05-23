using System.Collections.Generic;
using System.Threading.Tasks;
using DailyDietAPI.Model;
using DailyDietAPI.Services.Repositories;

namespace DailyDietAPI.Services
{
    public class MealService : IMealService
    {
        private readonly IMealRepository _mealRepository;

        public MealService(IMealRepository mealRepository)
        {
            _mealRepository = mealRepository;
        }

        public async Task<IEnumerable<Meal>> GetAllMealsAsync()
        {
            return await _mealRepository.GetAllAsync();
        }

        public async Task<Meal> GetMealByIdAsync(int id)
        {
            return await _mealRepository.GetByIdAsync(id);
        }

        public async Task<Meal> CreateMealAsync(Meal meal)
        {
            return await _mealRepository.AddAsync(meal);
        }

        public async Task<Meal> UpdateMealAsync(Meal meal)
        {
            return await _mealRepository.UpdateAsync(meal);
        }

        public async Task DeleteMealAsync(int id)
        {
            await _mealRepository.DeleteAsync(id);
        }
    }
} 