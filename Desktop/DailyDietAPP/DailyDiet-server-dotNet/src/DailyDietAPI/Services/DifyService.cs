using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Text.RegularExpressions;
using System.Collections.Generic;

namespace DailyDietAPI.Services
{
    public class DifyService : IDifyService
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;
        private readonly string _apiUrl;
        private readonly ILogger<DifyService> _logger;
        private readonly JsonSerializerOptions _jsonOptions;

        public DifyService(HttpClient httpClient, IConfiguration configuration, ILogger<DifyService> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
            _apiKey = configuration["Dify:ApiKey"] ?? throw new ArgumentNullException("Dify:ApiKey configuration is missing");
            _apiUrl = configuration["Dify:ApiUrl"] ?? throw new ArgumentNullException("Dify:ApiUrl configuration is missing");
            
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {_apiKey}");
            _logger.LogInformation($"DifyService initialized with API URL: {_apiUrl}");

            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
        }

        public async Task<string> SendMessageAsync(string message)
        {
            try
            {
                var request = new
                {
                    inputs = new { },
                    query = message,
                    response_mode = "blocking",
                    user = "user"
                };

                var content = new StringContent(
                    JsonSerializer.Serialize(request),
                    Encoding.UTF8,
                    "application/json"
                );

                var response = await _httpClient.PostAsync($"{_apiUrl}/chat-messages", content);
                var responseContent = await response.Content.ReadAsStringAsync();

                _logger.LogInformation($"Dify API yanıtı: {responseContent}");
                Console.WriteLine($"Dify API yanıtı: {responseContent}");

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"Dify API error: {response.StatusCode} - {responseContent}");
                    throw new Exception($"Dify API error: {response.StatusCode} - {responseContent}");
                }

                using var doc = JsonDocument.Parse(responseContent);
                if (doc.RootElement.TryGetProperty("answer", out var answerProp))
                {
                    return answerProp.GetString() ?? "Yanıt alınamadı";
                }
                return "Yanıt alınamadı";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SendMessageAsync: {Message}", ex.Message);
                Console.WriteLine("DifyService hata: " + ex.Message);
                throw;
            }
        }

        public async Task<List<object>> GetChatHistoryAsync()
        {
            try
            {
                var response = await _httpClient.GetAsync($"{_apiUrl}/chat-messages");
                response.EnsureSuccessStatusCode();

                var content = await response.Content.ReadAsStringAsync();
                return JsonSerializer.Deserialize<List<object>>(content, _jsonOptions);
            }
            catch (Exception ex)
            {
                throw new Exception($"Error getting chat history: {ex.Message}");
            }
        }

        public async Task ClearChatHistoryAsync()
        {
            try
            {
                var response = await _httpClient.DeleteAsync($"{_apiUrl}/chat-messages");
                response.EnsureSuccessStatusCode();
            }
            catch (Exception ex)
            {
                throw new Exception($"Error clearing chat history: {ex.Message}");
            }
        }

        public async Task<string> SendMessageAsync(string message, int age, int height, int weight, string gender, string goal, string name, string dietType)
        {
            try
            {
                if (string.IsNullOrEmpty(message))
                {
                    throw new ArgumentNullException(nameof(message), "Message cannot be null or empty");
                }

                var request = new
                {
                    inputs = new { 
                        yas = age.ToString(),
                        boy = height.ToString(),
                        kilo = weight.ToString(),
                        cinsiyet = gender,
                        hedef = goal,
                        isim = name,
                        diyet_tipi = dietType
                    },
                    query = message,
                    response_mode = "blocking",
                    user = "user"
                };

                var jsonRequest = JsonSerializer.Serialize(request);
                _logger.LogInformation($"Sending request to Dify API: {jsonRequest}");

                var content = new StringContent(
                    jsonRequest,
                    Encoding.UTF8,
                    "application/json");

                var response = await _httpClient.PostAsync($"{_apiUrl}/chat-messages", content);
                var responseContent = await response.Content.ReadAsStringAsync();

                _logger.LogInformation($"Response status code: {response.StatusCode}");
                _logger.LogInformation($"Response content: {responseContent}");

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"Dify API error: {response.StatusCode} - {responseContent}");
                    throw new Exception($"Dify API error: {response.StatusCode} - {responseContent}");
                }

                return responseContent;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SendMessageAsync: {Message}", ex.Message);
                throw;
            }
        }

        private class DifyResponse
        {
            public string Answer { get; set; }
            public string ConversationId { get; set; }
            public string MessageId { get; set; }
            public string Error { get; set; }
        }

        private class DifyAnswer
        {
            public string Answer { get; set; }
            public DifyData Data { get; set; }
        }

        private class DifyData
        {
            public UserProfile Profil { get; set; }
            public DietList DiyetListesi { get; set; }
        }

        private class UserProfile
        {
            public string Isim { get; set; }
            public int Yas { get; set; }
            public string Cinsiyet { get; set; }
            public int Boy { get; set; }
            public int Kilo { get; set; }
            public string Hedef { get; set; }
            public string DiyetTipi { get; set; }
        }

        private class DietList
        {
            public List<Water> Su { get; set; } = new List<Water>();
            public List<Meal> Kahvalti { get; set; } = new List<Meal>();
            public List<Meal> Ogle { get; set; } = new List<Meal>();
            public List<Meal> Aksam { get; set; } = new List<Meal>();
            public List<Meal> AraOgun { get; set; } = new List<Meal>();
        }

        private class Water
        {
            public string Su { get; set; }
        }

        private class Meal
        {
            public string Id { get; set; }
            public string Yemek { get; set; }
            public string Miktar { get; set; }
            public int Kalori { get; set; }
            public int Protein { get; set; }
            public int Karbonhidrat { get; set; }
            public double Yag { get; set; }
            public string Ogun { get; set; }
        }
    }
} 