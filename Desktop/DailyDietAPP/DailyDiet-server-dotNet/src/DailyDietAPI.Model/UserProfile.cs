namespace DailyDietAPI.Model
{
    public class UserProfile
    {
        public virtual long Id { get; set; }
        public virtual int AllowedCalories { get; set; }
        public virtual long UserId { get; set; }
        public virtual User User { get; set; } = null!;
    }
}
