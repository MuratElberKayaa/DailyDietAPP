using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using DailyDietAPI.Persistence;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using DailyDietAPI.Code.Extensions;
using DailyDietAPI.Code.Filters;
using DailyDietAPI.Features.Users;
using DailyDietAPI.Model;
using System.ComponentModel.DataAnnotations;

namespace DailyDietAPI.Features.Users
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly ILogger<UsersController> _logger;
        private readonly MealsDbContext _dbContext;
        private readonly UserManager<User> _userManager;

        public UsersController(
            ILogger<UsersController> logger, 
            MealsDbContext dbContext,
            UserManager<User> userManager)
        {
            _logger = logger;
            _dbContext = dbContext;
            _userManager = userManager;
        }

        /// <summary>
        /// Get profile of given user
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        [HttpGet]
        [Route("{userId}/profile")]
        [Authorize]
        public async Task<ActionResult<UserProfileDto>> GetProfile(long userId)
        {
            try
            {
                var currentUserId = User.Identity.GetUserId();
                if (currentUserId != userId)
                {
                    var userRoles = User.Identity.GetRoles();
                    if (!userRoles.Contains(RoleConsts.Admin) && !userRoles.Contains(RoleConsts.Manager))
                    {
                        return Forbid();
                    }
                }

                var user = await _dbContext.Set<User>()
                    .Include(u => u.Profile)
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                    return NotFound(new { message = "Kullanıcı bulunamadı." });

                var userDto = new UserProfileDto()
                {
                    AllowedCalories = user.Profile?.AllowedCalories ?? 0
                };

                return Ok(userDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Profil getirme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        /// <summary>
        /// Update profile of given user
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="userProfileDto"></param>
        /// <returns></returns>
        [HttpPut]
        [Route("{userId}/profile")]
        [AuthorizeSelfOrRoleAttribute("userId", RoleConsts.Admin, RoleConsts.Manager)]
        public async Task<IActionResult> UpdateProfile(long userId, [FromBody] UserProfileDto userProfileDto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(ModelState);

                using (var tx = TransactionScopeBuilder.New())
                {
                    var user = await _dbContext.Set<User>()
                        .Include(u => u.Profile)
                        .FirstOrDefaultAsync(u => u.Id == userId);

                    if (user == null)
                        return NotFound(new { message = "Kullanıcı bulunamadı." });

                    user.Profile = user.Profile ?? new UserProfile();
                    user.Profile.AllowedCalories = userProfileDto.AllowedCalories;
                    
                    await _dbContext.SaveChangesAsync();
                    tx.Complete();

                    return Ok(new { message = "Profil başarıyla güncellendi." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Profil güncelleme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        /// <summary>
        /// List all users (or just a single one)
        /// </summary>
        /// <param name="userId">If this value is passed as a query-string, single user detail will be returned...</param>
        /// <returns></returns>
        [HttpGet]
        [Route("")]
        [Authorize(Roles = RoleConsts.Admin + ", " + RoleConsts.Manager)]
        public async Task<ActionResult<IEnumerable<UserDetailsDto>>> GetUsers([FromQuery] long? userId)
        {
            try
            {
                var userQuery = _dbContext.Set<User>()
                    .Include(u => u.Profile)
                    .Select(u => new UserDetailsDto()
                    {
                        Id = u.Id,
                        Name = u.UserName,
                        AllowedCalories = u.Profile != null ? u.Profile.AllowedCalories : 0
                    });

                if (userId.HasValue)
                    userQuery = userQuery.Where(i => i.Id == userId);

                var users = await userQuery.ToListAsync();
                return Ok(users);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Kullanıcı listesi getirme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        /// <summary>
        /// Get's a list of user roles...
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        [HttpGet]
        [Route("{userId}/roles")]
        [Authorize(Roles = RoleConsts.Admin + ", " + RoleConsts.Manager)]
        public async Task<ActionResult<string[]>> GetRolesForUser(long userId)
        {
            try
            {
                var user = await _userManager.FindByIdAsync(userId.ToString());
                if (user == null)
                    return NotFound(new { message = "Kullanıcı bulunamadı." });

                var userRoles = await _userManager.GetRolesAsync(user);
                return Ok(userRoles);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Kullanıcı rolleri getirme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        /// <summary>
        /// Set's new roles for a given user/
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="newRoles"></param>
        /// <returns></returns>
        [HttpPut]
        [Route("{userId}/roles")]
        [Authorize(Roles = RoleConsts.Admin + ", " + RoleConsts.Manager)]
        public async Task<ActionResult> SetRolesForUser(long userId, [FromBody] string[] newRoles)
        {
            try
            {
                newRoles = newRoles ?? new string[0];

                var user = await _userManager.FindByIdAsync(userId.ToString());
                if (user == null)
                    return NotFound(new { message = "Kullanıcı bulunamadı." });

                var myRoles = User.Identity.GetRoles();
                var myRoleWeight = myRoles.Select(r => Array.IndexOf(RoleConsts.RoleOrder, r)).DefaultIfEmpty(-1).Max();

                var oldRoles = await _userManager.GetRolesAsync(user);           
                var rolesToAdd = newRoles.Where(nr => !oldRoles.Contains(nr)).ToList();
                var rolesToRemove = oldRoles.Where(or => !newRoles.Contains(or)).ToList();

                var cantManageRoles =
                    rolesToAdd.Where(r => Array.IndexOf(RoleConsts.RoleOrder, r) > myRoleWeight)
                    .Union(rolesToRemove.Where(r => Array.IndexOf(RoleConsts.RoleOrder, r) > myRoleWeight))
                    .ToList();

                if (cantManageRoles.Count > 0)
                    return StatusCode((int)HttpStatusCode.Forbidden, 
                        new { message = $"Bu rolleri değiştirme yetkiniz yok: {string.Join(", ", cantManageRoles)}" });

                await _userManager.AddToRolesAsync(user, rolesToAdd);
                await _userManager.RemoveFromRolesAsync(user, rolesToRemove);

                return Ok(new { message = "Kullanıcı rolleri başarıyla güncellendi." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Kullanıcı rolleri güncelleme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        /// <summary>
        /// Get all users with their IDs
        /// </summary>
        [HttpGet]
        [Route("list")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<UserListDto>>> ListUsers()
        {
            try
            {
                var users = await _dbContext.Set<User>()
                    .Select(u => new UserListDto
                    {
                        Id = u.Id,
                        UserName = u.UserName,
                        Email = u.Email
                    })
                    .ToListAsync();

                return Ok(users);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Kullanıcı listesi getirme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }
    }
}
