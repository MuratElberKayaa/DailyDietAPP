using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Threading.Tasks;
using DailyDietAPI.Model;
using DailyDietAPI.Persistence;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using Newtonsoft.Json;

namespace DailyDietAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DietPlanController : ControllerBase
    {
        private readonly MealsDbContext _context;

        public DietPlanController(MealsDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<IActionResult> SaveDietPlan([FromBody] DietPlan plan)
        {
            try
            {
                Console.WriteLine("GELEN PLAN: " + JsonConvert.SerializeObject(plan));
                if (plan == null)
                {
                    Console.WriteLine("Plan null!");
                    return BadRequest("Plan verisi boş olamaz.");
                }
                if (string.IsNullOrWhiteSpace(plan.Plan))
                {
                    Console.WriteLine("Plan içeriği boş!");
                    return BadRequest("Plan alanı boş olamaz.");
                }
                
                plan.CreatedAt = DateTime.UtcNow;
                _context.DietPlans.Add(plan);
                await _context.SaveChangesAsync();
                Console.WriteLine("Plan başarıyla kaydedildi. ID: " + plan.Id);
                return Ok(plan);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Plan kaydedilirken hata: " + ex.Message);
                return StatusCode(500, "Plan kaydedilirken bir hata oluştu: " + ex.Message);
            }
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetDietPlan(long userId)
        {
            var plan = await _context.DietPlans
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .FirstOrDefaultAsync();
            if (plan == null || string.IsNullOrWhiteSpace(plan.Plan))
                return NotFound("Kullanıcıya ait geçerli bir diyet planı bulunamadı.");
            return Ok(plan);
        }

        [HttpDelete("{userId}")]
        public async Task<IActionResult> DeleteDietPlans(long userId)
        {
            var plans = _context.DietPlans.Where(p => p.UserId == userId);
            if (!plans.Any())
                return NotFound("Kullanıcıya ait diyet planı bulunamadı.");
            _context.DietPlans.RemoveRange(plans);
            await _context.SaveChangesAsync();
            return Ok("Kullanıcıya ait tüm diyet planları silindi.");
        }
    }
} 