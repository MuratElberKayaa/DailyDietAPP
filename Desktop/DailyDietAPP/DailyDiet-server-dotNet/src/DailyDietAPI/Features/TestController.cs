using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using DailyDietAPI.Persistence;
using DailyDietAPI.Features.Meals;
using DailyDietAPI.Model;
using System.Threading.Tasks;
using DailyDietAPI.Features.Users;

namespace DailyDietAPI.Features
{
	[AllowAnonymous]
	[ApiController]	
	[Route("[controller]")]
	public class TestController : ControllerBase
	{
		private ILogger<UsersController> logger;
		private MealsDbContext dbContext;
		private UserManager<User> userManager;

		public TestController(
			ILogger<UsersController> logger,
			MealsDbContext dbContext,
			UserManager<User> userManager
			)
		{
			this.logger = logger;
			this.dbContext = dbContext;
			this.userManager = userManager;
		}

		[HttpGet]
		public async Task<IActionResult> Test()
		{
			var user = await userManager.FindByNameAsync("admin");
			var tokenEmail = await userManager.GenerateChangeEmailTokenAsync(user, "admin@email.com");
			var tokenPwd = await userManager.GeneratePasswordResetTokenAsync(user);

			var rEmail = await userManager.ConfirmEmailAsync(user, tokenEmail);
			var rPwd = await userManager.ResetPasswordAsync(user, tokenPwd, "1234");

			await userManager.UpdateSecurityStampAsync(user);
			return Ok(new { message = "Test completed successfully" });
		}
	}
}
