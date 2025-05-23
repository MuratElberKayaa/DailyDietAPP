using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using DailyDietAPI.Model;
using DailyDietAPI.Persistence;

namespace DailyDietAPI.Services.Repositories
{
    public class MealRepository : IMealRepository
    {
        private readonly MealsDbContext _context;

        public MealRepository(MealsDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Meal>> GetAllAsync()
        {
            return await _context.Meals.ToListAsync();
        }

        public async Task<Meal> GetByIdAsync(int id)
        {
            return await _context.Meals.FindAsync(id);
        }

        public async Task<Meal> AddAsync(Meal meal)
        {
            await _context.Meals.AddAsync(meal);
            await _context.SaveChangesAsync();
            return meal;
        }

        public async Task<Meal> UpdateAsync(Meal meal)
        {
            _context.Meals.Update(meal);
            await _context.SaveChangesAsync();
            return meal;
        }

        public async Task DeleteAsync(int id)
        {
            var meal = await _context.Meals.FindAsync(id);
            if (meal != null)
            {
                _context.Meals.Remove(meal);
                await _context.SaveChangesAsync();
            }
        }
    }
} 