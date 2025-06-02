using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DailyDietAPI.Model
{
    public class DietPlan
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
        public long UserId { get; set; }
        public string Plan { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
    }
} 