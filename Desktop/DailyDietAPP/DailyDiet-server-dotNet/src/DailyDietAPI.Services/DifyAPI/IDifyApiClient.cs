using System.Threading.Tasks;

namespace DailyDietAPI.Services.DifyAPI
{
    public interface IDifyApiClient
    {
        Task<string> SendMessageAsync(string message, string userId, string conversationId = null);
        Task<string> GetCompletionAsync(string prompt);
    }
} 