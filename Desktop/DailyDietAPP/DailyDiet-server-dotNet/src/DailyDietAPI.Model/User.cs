using Microsoft.AspNetCore.Identity;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json;

namespace DailyDietAPI.Model
{
    public class User : IdentityUser<long>
    {
        public UserProfile? Profile { get; set; }

        [JsonIgnore]
        public virtual ICollection<UserMeals> Meals { get; set; }

        [Required]
        [EmailAddress]
        public override string Email { get; set; }

        public override string UserName
        {
            get => Email;
            set => Email = value;
        }

        public User()
        {
            // NOTE:
            // https://stackoverflow.com/questions/20757594/ef-codefirst-should-i-initialize-navigation-properties
            //
            // While creating a N:1 dependency here does a mess (won't get saved if not reassigned),
            // Profile = new UserProfile();
            // ...the creation of internal collections is a good practice (needed at initialization and seed due the way how User is created inside identity and user manager)!
            Meals = new List<UserMeals>();
        }
    }
}
