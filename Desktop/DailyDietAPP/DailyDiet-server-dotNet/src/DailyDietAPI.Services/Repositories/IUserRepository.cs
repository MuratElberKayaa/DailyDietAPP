using System.Collections.Generic;
using System.Threading.Tasks;
using DailyDietAPI.Model;

namespace DailyDietAPI.Services.Repositories
{
    public interface IUserRepository
    {
        Task<IEnumerable<User>> GetAllAsync();
        Task<User> GetByIdAsync(long id);
        Task<User> GetByEmailAsync(string email);
        Task<User> AddAsync(User user, string password);
        Task<User> UpdateAsync(User user);
        Task DeleteAsync(long id);
        Task<bool> ValidatePasswordAsync(User user, string password);
    }
} 