using Microsoft.AspNetCore.Mvc;
using DailyDietAPI.Services;
using System.Threading.Tasks;

namespace DailyDietAPI.Features
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatbotController : ControllerBase
    {
        private readonly IDifyService _difyService;
        public ChatbotController(IDifyService difyService)
        {
            _difyService = difyService;
        }

        [HttpPost("ask")]
        public async Task<IActionResult> Ask([FromBody] ChatRequestDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Message))
                return BadRequest(new { error = "Mesaj boş olamaz." });

            try
            {
                var answer = await _difyService.SendMessageAsync(dto.Message);
                return Ok(new { answer });
            }
            catch (System.Exception ex)
            {
                // Hata logla
                Console.WriteLine("Chatbot hata: " + ex.Message);
                return StatusCode(500, new { error = "Chatbot servisiyle iletişimde hata oluştu.", detail = ex.Message });
            }
        }
    }
} 