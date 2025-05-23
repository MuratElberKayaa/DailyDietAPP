using System;

namespace DailyDietAPI.Model
{
    public class Meal
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Description { get; set; }
        public DateTime MealTime { get; set; }
        public int Calories { get; set; }
        public long? UserId { get; set; }
        public User? User { get; set; }
    }
} 