using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;

namespace DailyDietAPI.Services.DifyAPI
{
    public class DifyApiClient : IDifyApiClient
    {
        private readonly HttpClient _httpClient;
        private readonly DifyApiSettings _settings;

        public DifyApiClient(HttpClient httpClient, IOptions<DifyApiSettings> settings)
        {
            _httpClient = httpClient;
            _settings = settings.Value;
            
            _httpClient.BaseAddress = new Uri(_settings.BaseUrl);
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {_settings.ApiKey}");
        }

        public async Task<string> SendMessageAsync(string message, string userId, string conversationId = null)
        {
            var request = new Dictionary<string, object>
            {
                { "query", message },
                { "response_mode", "blocking" },
                { "user", userId },
                { "inputs", new { } }
            };
            if (!string.IsNullOrEmpty(conversationId))
            {
                request["conversation_id"] = conversationId;
            }

            var content = new StringContent(
                JsonSerializer.Serialize(request),
                Encoding.UTF8,
                "application/json");

            var response = await _httpClient.PostAsync("/v1/chat-messages", content);
            var responseContent = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"Dify API error: {response.StatusCode} - {responseContent}");
            }
            if (string.IsNullOrWhiteSpace(responseContent) || !responseContent.TrimStart().StartsWith("{"))
            {
                throw new Exception($"Dify API non-JSON response: {responseContent}");
            }
            var result = JsonSerializer.Deserialize<JsonElement>(responseContent);
            return result.GetProperty("answer").GetString();
        }

        public async Task<string> GetCompletionAsync(string prompt)
        {
            var request = new
            {
                prompt = prompt,
                response_mode = "blocking"
            };

            var content = new StringContent(
                JsonSerializer.Serialize(request),
                Encoding.UTF8,
                "application/json");

            var response = await _httpClient.PostAsync("/v1/completion-messages", content);
            response.EnsureSuccessStatusCode();

            var responseContent = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<JsonElement>(responseContent);

            return result.GetProperty("text").GetString();
        }
    }
} 