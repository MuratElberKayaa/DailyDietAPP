using System.Threading.Tasks;
using DailyDietAPI.Model;
using DailyDietAPI.Services.Repositories;

namespace DailyDietAPI.Services
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _userRepository;

        public UserService(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<User> GetUserByIdAsync(long id)
        {
            return await _userRepository.GetByIdAsync(id);
        }

        public async Task<User> GetUserByEmailAsync(string email)
        {
            return await _userRepository.GetByEmailAsync(email);
        }

        public async Task<User> CreateUserAsync(User user, string password)
        {
            return await _userRepository.AddAsync(user, password);
        }

        public async Task<User> UpdateUserAsync(User user)
        {
            return await _userRepository.UpdateAsync(user);
        }

        public async Task DeleteUserAsync(long id)
        {
            await _userRepository.DeleteAsync(id);
        }

        public async Task<bool> ValidateUserAsync(string email, string password)
        {
            var user = await _userRepository.GetByEmailAsync(email);
            if (user == null)
            {
                return false;
            }

            // Password validation will be handled by the repository
            return await _userRepository.ValidatePasswordAsync(user, password);
        }
    }
} 