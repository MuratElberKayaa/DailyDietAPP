using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace DailyDietAPI.Services
{
    public interface IDifyService
    {
        Task<string> SendMessageAsync(string message);
        Task<List<object>> GetChatHistoryAsync();
        Task ClearChatHistoryAsync();
        Task<string> SendMessageAsync(string message, int age, int height, int weight, string gender, string goal, string name, string dietType);
    }
} 