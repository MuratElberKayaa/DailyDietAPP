using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using DailyDietAPI.Services;

namespace DailyDietAPI.Features
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DifyController : ControllerBase
    {
        private readonly IDifyService _difyService;
        private readonly ILogger<DifyController> _logger;

        public DifyController(IDifyService difyService, ILogger<DifyController> logger)
        {
            _difyService = difyService;
            _logger = logger;
        }

        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] ChatRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.Message))
                {
                    return BadRequest("Message cannot be empty");
                }

                var response = await _difyService.SendMessageAsync(
                    request.Message, 
                    request.Age, 
                    request.Height,
                    request.Weight,
                    request.Gender,
                    request.Goal,
                    request.Name,
                    request.DietType
                );
                return Ok(new { response });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in chat endpoint");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    public class ChatRequest
    {
        public string Message { get; set; }
        public int Age { get; set; }
        public int Height { get; set; }
        public int Weight { get; set; }
        public string Gender { get; set; }
        public string Goal { get; set; }
        public string Name { get; set; }
        public string DietType { get; set; }
    }
} 