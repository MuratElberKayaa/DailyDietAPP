using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using DailyDietAPI.Persistence;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using DailyDietAPI.Code.Filters;
using DailyDietAPI.Model;
using DailyDietAPI.Code.Extensions;
using Microsoft.EntityFrameworkCore;
using System;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace DailyDietAPI.Features.Meals
{
    /// <summary>
    /// NOTE: the omitting of the default version and such route is not out-of the box, not that route is added both to the v1 as v2 docs!
    /// </summary>
    [ApiController]
    [Route("api/v1/[controller]")]
    [ApiVersion("1.0")]
    [Authorize]
    public class MealsController : ControllerBase
    {
        private readonly ILogger<MealsController> _logger;
        private readonly MealsDbContext _dbContext;

        public MealsController(ILogger<MealsController> logger, MealsDbContext dbContext)
        {
            _logger = logger;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("users/{userId}/meals/{mealId}")]
        [AuthorizeSelfOrRoleAttribute("userId", RoleConsts.Admin, RoleConsts.Manager)]
        [ProducesResponseType(typeof(MealDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<ActionResult<MealDto>> GetMeal(long userId, long mealId)
        {
            try
            {
                var mealQuery =
                    from u in _dbContext.Set<User>()
                    from m in u.Meals
                    where u.Id == userId && m.Id == mealId
                    select new MealDto()
                    {
                        Date = m.Date,
                        Calories = m.Calories,
                        Description = m.Description
                    };

                var meal = await mealQuery.FirstOrDefaultAsync();
                if (meal == null)
                    return NotFound(new { message = "Yemek bulunamadı." });

                return Ok(meal);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Yemek getirme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        /// <summary>
        /// Creates a new meal entry for the given user
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="mealDto"></param>
        /// <returns>Unique ID of the given UserMeal entry; The Location header will also be set and the URL to access the newly created item will be set there.</returns>
        [HttpPost]
        [Route("users/{userId}/meals")]
        [AuthorizeSelfOrRoleAttribute("userId", RoleConsts.Admin, RoleConsts.Manager)]
        [ProducesResponseType(typeof(MealDto), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> CreateMeal(long userId, [FromBody] MealDto mealDto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { message = "Geçersiz veri formatı", errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                using (var tx = TransactionScopeBuilder.New())
                {
                    var user = await _dbContext.Set<User>().FirstOrDefaultAsync(u => u.Id == userId);
                    if (user == null)
                        return NotFound(new { message = "Kullanıcı bulunamadı." });

                    var meal = new UserMeals()
                    {
                        Date = mealDto.Date,
                        Calories = mealDto.Calories,
                        Description = mealDto.Description
                    };

                    user.Meals.Add(meal);
                    await _dbContext.SaveChangesAsync();
                    tx.Complete();

                    return CreatedAtAction(nameof(GetMeal), new { userId = userId, mealId = meal.Id }, meal);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Yemek oluşturma işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        [HttpPut]
        [Route("users/{userId}/meals/{mealId}")]
        [AuthorizeSelfOrRoleAttribute("userId", RoleConsts.Admin, RoleConsts.Manager)]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> UpdateMeal(long userId, long mealId, [FromBody] MealDto mealDto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { message = "Geçersiz veri formatı", errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                using (var tx = TransactionScopeBuilder.New())
                {
                    var meal = await (
                        from u in _dbContext.Set<User>()
                        from m in u.Meals
                        where u.Id == userId && m.Id == mealId
                        select m
                    ).FirstOrDefaultAsync();

                    if (meal == null)
                        return NotFound(new { message = "Güncellenecek yemek bulunamadı." });

                    meal.Date = mealDto.Date;
                    meal.Calories = mealDto.Calories;
                    meal.Description = mealDto.Description;

                    await _dbContext.SaveChangesAsync();
                    tx.Complete();

                    return Ok(new { message = "Yemek başarıyla güncellendi." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Yemek güncelleme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        [HttpDelete]
        [Route("users/{userId}/meals/{mealId}")]
        [AuthorizeSelfOrRoleAttribute("userId", RoleConsts.Admin, RoleConsts.Manager)]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> DeleteMeal(long userId, long mealId)
        {
            try
            {
                using (var tx = TransactionScopeBuilder.New())
                {
                    var result = await (
                        from u in _dbContext.Set<User>()
                        from m in u.Meals
                        where u.Id == userId && m.Id == mealId
                        select new { User = u, Meal = m }
                    ).FirstOrDefaultAsync();

                    if (result == null)
                        return NotFound(new { message = "Silinmek istenen yemek bulunamadı." });

                    result.User.Meals.Remove(result.Meal);
                    await _dbContext.SaveChangesAsync();
                    tx.Complete();

                    return Ok(new { message = "Yemek başarıyla silindi." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Yemek silme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        /// <summary>
        /// Gets a list of mails (with possible filtering).
        /// NOTE: originally would have used OData (flexible filtering and KENDO has support for creating queries in a structured fashion), but within .NET Core 3 OData is not functional yet (see: https://github.com/OData/WebApi/issues/1748).
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        [HttpGet]
        [Route("users/{userId}/meals")]
        [AuthorizeSelfOrRoleAttribute("userId", RoleConsts.Admin, RoleConsts.Manager)]
        [ODataQueryableAttribute]
        [ProducesResponseType(typeof(IEnumerable<MealDailySummaryDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<ActionResult<IEnumerable<MealDailySummaryDto>>> GetMeals(
            long userId,
            [FromQuery] DateTime? dateFrom,
            [FromQuery] DateTime? dateTo,
            [FromQuery] TimeSpan? timeFrom,
            [FromQuery] TimeSpan? timeTo)
        {
            try
            {
                var user = await _dbContext.Set<User>()
                    .Include(u => u.Profile)
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                    return NotFound(new { message = "Kullanıcı bulunamadı." });

                var mealFilterOptionsDto = new MealFilterOptionsDto()
                {
                    DateFrom = dateFrom,
                    DateTo = dateTo,
                    TimeFrom = timeFrom,
                    TimeTo = timeTo
                };

                var mealsDailySummaryQuery =
                    from u in _dbContext.Set<User>().Include(u => u.Profile).DefaultIfEmpty()
                    from m in u.Meals
                    where u.Id == userId
                    group m by m.Date.Date into g
                    orderby g.Key descending
                    select new
                    {
                        Day = g.Key,
                        MealsCount = g.Count(),
                        DailyCaloriesConsumed = g.Sum(m => m.Calories),
                        DailyCaloriesExceeded = g.Sum(m => m.Calories) > (user.Profile != null ? user.Profile.AllowedCalories : 0)
                    };

                var mealsTimeFilteredQuery =
                    from u in _dbContext.Set<User>()
                    from m in u.Meals
                    where u.Id == userId
                    orderby m.Date ascending
                    select m;

                if (mealFilterOptionsDto.DateFrom != null)
                {
                    mealsDailySummaryQuery = mealsDailySummaryQuery.Where(m => m.Day >= mealFilterOptionsDto.DateFrom.Value.Date);
                    mealsTimeFilteredQuery = mealsTimeFilteredQuery.Where(m => m.Date >= mealFilterOptionsDto.DateFrom.Value.Date);
                }
                if (mealFilterOptionsDto.DateTo != null)
                {
                    mealsDailySummaryQuery = mealsDailySummaryQuery.Where(m => m.Day < mealFilterOptionsDto.DateTo.Value.Date);
                    mealsTimeFilteredQuery = mealsTimeFilteredQuery.Where(m => m.Date < mealFilterOptionsDto.DateTo.Value.Date);
                }

                if (mealFilterOptionsDto.TimeFrom != null)
                    mealsTimeFilteredQuery = mealsTimeFilteredQuery.Where(m => m.Date.TimeOfDay >= mealFilterOptionsDto.TimeFrom.Value);
                if (mealFilterOptionsDto.TimeTo != null)
                    mealsTimeFilteredQuery = mealsTimeFilteredQuery.Where(m => m.Date.TimeOfDay < mealFilterOptionsDto.TimeTo.Value);

                var mealsDailySummary = await mealsDailySummaryQuery.ToListAsync();
                var meals = await mealsTimeFilteredQuery.ToListAsync();

                var groupQuery =
                    from ms in mealsDailySummary
                    select new MealDailySummaryDto()
                    {
                        Day = ms.Day,
                        MealsCount = ms.MealsCount,
                        DailyCaloriesConsumed = ms.DailyCaloriesConsumed,
                        DailyCaloriesExceeded = ms.DailyCaloriesExceeded,
                        Meals =
                            from m in meals
                            where m.Date.Date == ms.Day
                            select new MealDailySummaryDto.MealDailyItemDto()
                            {
                                Id = m.Id,
                                Date = m.Date,
                                Calories = m.Calories,
                                Description = m.Description
                            }
                    };

                return Ok(groupQuery);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Yemek listesi getirme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }

        /// <summary>
        /// Gets a list of mails (with possible filtering).
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        [HttpGet]
        [Route("advanced")]
        [ODataQueryableAttribute]
        [AuthorizeSelfOrRoleAttribute("userId", RoleConsts.Admin, RoleConsts.Manager)]
        [ProducesResponseType(typeof(IEnumerable<MealDailySummaryDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<ActionResult<IEnumerable<MealDailySummaryDto>>> GetMealsAdvanced(
            long userId)
        {
            try
            {
                var user = await _dbContext.Set<User>()
                    .Include(u => u.Profile)
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                    return NotFound(new { message = "Kullanıcı bulunamadı." });

                var allowedCalories = user.Profile?.AllowedCalories ?? 0;

                var mealsDailySummaryQuery =
                    from u in _dbContext.Set<User>()
                    from m in u.Meals
                    where u.Id == userId
                    group m by m.Date.Date into g
                    select new MealDailySummaryDto()
                    {
                        Day = g.Key,
                        MealsCount = g.Count(),
                        DailyCaloriesConsumed = g.Sum(m => m.Calories),
                        DailyCaloriesExceeded = g.Sum(m => m.Calories) > allowedCalories,
                        Meals = g
                            .Select(m => new MealDailySummaryDto.MealDailyItemDto()
                            {
                                Id = m.Id,
                                Date = m.Date,
                                Calories = m.Calories,
                                Description = m.Description
                            })
                    };

                return Ok(mealsDailySummaryQuery);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Gelişmiş yemek listesi getirme işlemi sırasında hata oluştu");
                return StatusCode(500, new { message = "Bir hata oluştu, lütfen daha sonra tekrar deneyin" });
            }
        }
    }
}



/*
    //
    // NOTE:
    // the code below is for EF6 (EDMX) - some names were slightly changed (due EDMX conventions)
    // works as a one shot, single SQL call version
    //
    // special "care" on date/time format is needed

    var dbContext = new TTMealsEntities();
            
    var user = dbContext.Set<AspNetUsers>().Include(u => u.UserProfile).First(u => u.Id == userId);

    var fromTimeStr = mealFilterOptionsDto.TimeFrom != null ? mealFilterOptionsDto.TimeFrom.Value.ToString(@"hh\:mm\:ss\.fffffff") : null;
    var toTimeStr = mealFilterOptionsDto.TimeTo != null ? mealFilterOptionsDto.TimeTo.Value.ToString(@"hh\:mm\:ss\.fffffff") : null;

    var mealsDailySummaryQuery =
        from u in dbContext.Set<AspNetUsers>()
        from m in u.UserMeal
        // NOTE: no need to "trim" dates here: DbFunctions.TruncateTime(m.Date)
        where (mealFilterOptionsDto.DateFrom == null || m.Date >= mealFilterOptionsDto.DateFrom) && (mealFilterOptionsDto.DateTo == null || m.Date < mealFilterOptionsDto.DateTo)
        group m by DbFunctions.TruncateTime(m.Date) into g
        select new
        {
            Day = g.Key,
            MealsCount = g.Count(),
            DailyCaloriesConsumed = g.Sum(m => m.Calories),
            DailyCaloriesExceeded = g.Sum(m => m.Calories) > user.UserProfile.AllowedCalories,
            Meals = g
                // NOTE: just string based comparison works for time-parts, or computed column (inside VIEW !!!)
                .Where(m => (mealFilterOptionsDto.TimeFrom == null || string.Compare(m.Date.ToString().Substring(11), fromTimeStr) >= 0) && (mealFilterOptionsDto.TimeTo == null || string.Compare(m.Date.ToString().Substring(11), toTimeStr) < 0))
                .Select(m => new
                {
                    m.Id,
                    m.Date,
                    m.Description,
                    m.Calories
                })
        };

    //
    // NOTE:
    // the same with EF core won't work until grouping issues are not solved there

    var user = dbContext.Set<AspNetUsers>().Include(u => u.Profile).First(u => u.Id == userId);

    var mealsDailySummaryQuery =
        from u in dbContext.Set<User>()
        from m in u.Meals
        where (mealFilterOptionsDto.DateFrom == null || m.Date >= mealFilterOptionsDto.DateFrom) && (mealFilterOptionsDto.DateTo == null || m.Date < mealFilterOptionsDto.DateTo)
        group m by m.Date.Date into g
        select new
        {
            Day = g.Key,
            MealsCount = g.Count(),
            DailyCaloriesConsumed = g.Sum(m => m.Calories),
            DailyCaloriesExceeded = g.Sum(m => m.Calories) > user.Profile.AllowedCalories,
            Meals = g
                .Where(m => (mealFilterOptionsDto.TimeFrom == null || m.Date.TimeOfDay >= mealFilterOptionsDto.TimeFrom) && (mealFilterOptionsDto.TimeTo == null || m.Date.TimeOfDay < mealFilterOptionsDto.TimeTo))
                .Select(m => new
                {
                    m.Id,
                    m.Date,
                    m.Description,
                    m.Calories
                })
        };

 */
