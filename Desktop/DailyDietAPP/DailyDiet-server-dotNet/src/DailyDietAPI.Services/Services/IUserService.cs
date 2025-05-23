using System.Threading.Tasks;
using DailyDietAPI.Model;

namespace DailyDietAPI.Services
{
    public interface IUserService
    {
        Task<User> GetUserByIdAsync(long id);
        Task<User> GetUserByEmailAsync(string email);
        Task<User> CreateUserAsync(User user, string password);
        Task<User> UpdateUserAsync(User user);
        Task DeleteUserAsync(long id);
        Task<bool> ValidateUserAsync(string email, string password);
    }
} 