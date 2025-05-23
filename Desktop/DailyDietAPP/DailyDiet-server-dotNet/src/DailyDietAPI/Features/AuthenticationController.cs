using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using DailyDietAPI.Code.Extensions;
using DailyDietAPI.Model;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace DailyDietAPI.Features
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthenticationController : ControllerBase
    {
        private readonly ILogger<AuthenticationController> _logger;
        private readonly IConfiguration _configuration;
        private readonly UserManager<User> _userManager;
        private readonly SignInManager<User> _signInManager;
        private readonly RoleManager<IdentityRole<long>> _roleManager;

        public AuthenticationController(
            ILogger<AuthenticationController> logger,
            IConfiguration configuration,
            UserManager<User> userManager,
            SignInManager<User> signInManager,
            RoleManager<IdentityRole<long>> roleManager)
        {
            _logger = logger;
            _configuration = configuration;
            _userManager = userManager;
            _signInManager = signInManager;
            _roleManager = roleManager;
        }

        public class LoginRequest
        {
            [Required(ErrorMessage = "E-posta adresi zorunludur")]
            [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz")]
            public string Email { get; set; }

            [Required(ErrorMessage = "Şifre zorunludur")]
            public string Password { get; set; }
        }

        public class RegisterRequest
        {
            [Required(ErrorMessage = "E-posta adresi zorunludur")]
            [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz")]
            public string Email { get; set; }

            [Required(ErrorMessage = "Şifre zorunludur")]
            [StringLength(100, MinimumLength = 6, ErrorMessage = "Şifre en az 6 karakter olmalıdır")]
            public string Password { get; set; }
        }

        public class AuthResponse
        {
            public string Token { get; set; }
            public DateTime Expiration { get; set; }
            public string Email { get; set; }
            public string[] Roles { get; set; }
        }

        /// <summary>
        /// Kullanıcı girişi (Login)
        /// </summary>
        [AllowAnonymous]
        [HttpPost("login")]
        [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
        {
            try
            {
                if (request == null)
                {
                    _logger.LogWarning("Login isteği boş gönderildi");
                    return BadRequest(new { message = "Geçersiz istek formatı" });
                }

                if (!ModelState.IsValid)
                {
                    var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
                    _logger.LogWarning("Login isteği geçersiz: {Errors}", string.Join(", ", errors));
                    return BadRequest(new { message = "Geçersiz veri formatı", errors });
                }

                var user = await _userManager.FindByEmailAsync(request.Email);
                if (user == null)
                {
                    _logger.LogWarning("Geçersiz e-posta adresi denemesi: {Email}", request.Email);
                    return Unauthorized(new { message = "Geçersiz e-posta adresi veya şifre" });
                }

                var signInResult = await _signInManager.CheckPasswordSignInAsync(user, request.Password, false);
                if (!signInResult.Succeeded)
                {
                    _logger.LogWarning("Geçersiz şifre denemesi kullanıcı için: {Email}", request.Email);
                    return Unauthorized(new { message = "Geçersiz e-posta adresi veya şifre" });
                }

                var userRoles = await _userManager.GetRolesAsync(user);
                var token = GenerateJwtToken(user);

                _logger.LogInformation("Başarılı login: {Email}", user.Email);

                return Ok(new AuthResponse
                {
                    Token = token,
                    Expiration = DateTime.UtcNow.AddMinutes(int.Parse(_configuration["Jwt:ExpiryInMinutes"])),
                    Email = user.Email,
                    Roles = userRoles.ToArray()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Login işlemi sırasında beklenmeyen hata: {Message}", ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Kullanıcı kaydı (Register)
        /// </summary>
        [AllowAnonymous]
        [HttpPost("register")]
        [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request)
        {
            try
            {
                if (request == null)
                {
                    _logger.LogWarning("Register isteği boş gönderildi");
                    return BadRequest(new { message = "Geçersiz istek formatı" });
                }

                if (!ModelState.IsValid)
                {
                    var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
                    _logger.LogWarning("Register isteği geçersiz: {Errors}", string.Join(", ", errors));
                    return BadRequest(new { message = "Geçersiz veri formatı", errors });
                }

                var existingUser = await _userManager.FindByEmailAsync(request.Email);
                if (existingUser != null)
                {
                    _logger.LogWarning("E-posta adresi zaten kullanımda: {Email}", request.Email);
                    return BadRequest(new { message = "Bu e-posta adresi zaten kullanılıyor" });
                }

                var user = new User
                {
                    Email = request.Email,
                    UserName = request.Email
                };

                var result = await _userManager.CreateAsync(user, request.Password);

                if (!result.Succeeded)
                {
                    var errors = result.Errors.Select(e => e.Description);
                    _logger.LogWarning("Kullanıcı oluşturulamadı: {Errors}", string.Join(", ", errors));
                    return BadRequest(new { message = "Kullanıcı oluşturulamadı", errors });
                }

                // Kullanıcıya varsayılan rol atama
                await _userManager.AddToRoleAsync(user, "User");

                // JWT token oluşturma
                var token = GenerateJwtToken(user);

                _logger.LogInformation("Yeni kullanıcı oluşturuldu: {Email}", request.Email);

                return Ok(new AuthResponse
                {
                    Token = token,
                    Expiration = DateTime.UtcNow.AddMinutes(Convert.ToDouble(_configuration["Jwt:ExpiryInMinutes"])),
                    Email = user.Email,
                    Roles = new[] { "User" }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Register işlemi sırasında beklenmeyen hata: {Message}", ex.Message);
                throw; // Let the middleware handle the error
            }
        }

        private string GenerateJwtToken(User user)
        {
            try
            {
                if (user == null)
                {
                    throw new ArgumentNullException(nameof(user), "Kullanıcı bilgisi boş olamaz.");
                }

                if (string.IsNullOrEmpty(user.Email))
                {
                    throw new ArgumentException("Kullanıcı e-posta adresi boş olamaz.", nameof(user));
                }

                var jwtKey = _configuration["Jwt:Key"];
                var jwtIssuer = _configuration["Jwt:Issuer"];
                var jwtAudience = _configuration["Jwt:Audience"];
                var jwtExpiryInMinutes = _configuration["Jwt:ExpiryInMinutes"];

                if (string.IsNullOrEmpty(jwtKey))
                {
                    throw new InvalidOperationException("JWT anahtarı yapılandırılmamış.");
                }

                if (string.IsNullOrEmpty(jwtIssuer))
                {
                    throw new InvalidOperationException("JWT Issuer yapılandırılmamış.");
                }

                if (string.IsNullOrEmpty(jwtAudience))
                {
                    throw new InvalidOperationException("JWT Audience yapılandırılmamış.");
                }

                if (string.IsNullOrEmpty(jwtExpiryInMinutes))
                {
                    throw new InvalidOperationException("JWT ExpiryInMinutes yapılandırılmamış.");
                }

                var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
                var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

                var userRoles = _userManager.GetRolesAsync(user).Result;
                var claims = new List<Claim>
                {
                    new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                    new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                    new Claim(ClaimTypes.Name, user.Email),
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString())
                };

                // Rolleri claims'e ekle
                foreach (var role in userRoles)
                {
                    claims.Add(new Claim(ClaimTypes.Role, role));
                }

                var token = new JwtSecurityToken(
                    issuer: jwtIssuer,
                    audience: jwtAudience,
                    claims: claims,
                    expires: DateTime.UtcNow.AddMinutes(int.Parse(jwtExpiryInMinutes)),
                    signingCredentials: credentials
                );

                return new JwtSecurityTokenHandler().WriteToken(token);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "JWT token oluşturulurken hata: {Message}", ex.Message);
                throw new InvalidOperationException("Token oluşturulamadı: " + ex.Message);
            }
        }
    }
}
