using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Threading.Tasks;
using DailyDietAPI.Services;
using System.Collections.Generic;

namespace DailyDietAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ChatbotController : ControllerBase
    {
        private readonly IDifyService _difyService;

        public ChatbotController(IDifyService difyService)
        {
            _difyService = difyService;
        }

        [HttpPost("send")]
        public async Task<IActionResult> SendMessage([FromBody] ChatMessageRequest request)
        {
            try
            {
                var response = await _difyService.SendMessageAsync(request.Message);
                return Ok(response);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetHistory()
        {
            try
            {
                var history = await _difyService.GetChatHistoryAsync();
                return Ok(history);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("history")]
        public async Task<IActionResult> ClearHistory()
        {
            try
            {
                await _difyService.ClearChatHistoryAsync();
                return Ok(new { message = "Chat history cleared successfully" });
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }

    public class ChatMessageRequest
    {
        public string Message { get; set; }
    }
} 