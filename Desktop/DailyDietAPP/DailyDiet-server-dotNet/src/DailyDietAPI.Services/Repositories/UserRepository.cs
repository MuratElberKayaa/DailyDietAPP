using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using DailyDietAPI.Model;
using DailyDietAPI.Persistence;

namespace DailyDietAPI.Services.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly MealsDbContext _context;

        public UserRepository(MealsDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<User>> GetAllAsync()
        {
            return await _context.Users.ToListAsync();
        }

        public async Task<User> GetByIdAsync(long id)
        {
            return await _context.Users.FindAsync(id);
        }

        public async Task<User> GetByEmailAsync(string email)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        }

        public async Task<User> AddAsync(User user, string password)
        {
            // Password hashing will be handled by the repository implementation
            await _context.Users.AddAsync(user);
            await _context.SaveChangesAsync();
            return user;
        }

        public async Task<User> UpdateAsync(User user)
        {
            _context.Users.Update(user);
            await _context.SaveChangesAsync();
            return user;
        }

        public async Task DeleteAsync(long id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user != null)
            {
                _context.Users.Remove(user);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<bool> ValidatePasswordAsync(User user, string password)
        {
            // Basic password validation - in a real application, you would use proper password hashing
            // This is just a placeholder implementation
            return user.PasswordHash == password;
        }
    }
} 