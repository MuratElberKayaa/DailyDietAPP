import 'dart:convert';

class DietPlan {
  final List<Meal> meals;
  
  DietPlan({required this.meals});
  
  factory DietPlan.fromJson(Map<String, dynamic> json) {
    return DietPlan(
      meals: (json['ogunler'] as List?)?.map((meal) => Meal.fromJson(meal as Map<String, dynamic>)).toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'ogunler': meals.map((meal) => meal.toJson()).toList(),
    };
  }

  static DietPlan? fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return DietPlan.fromJson(json);
    } catch (e) {
      print('Error parsing diet plan JSON: $e');
      return null;
    }
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class Meal {
  final String name;
  final List<Food> foods;
  
  Meal({required this.name, required this.foods});
  
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['ogunAdi']?.toString() ?? 'Bilinmeyen',
      foods: (json['yemekler'] as List?)?.map((food) => Food.fromJson(food as Map<String, dynamic>)).toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'ogunAdi': name,
      'yemekler': foods.map((food) => food.toJson()).toList(),
    };
  }
}

class Food {
  final String name;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  
  Food({
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });
  
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['yemek']?.toString() ?? '',
      calories: (json['kalori'] is int)
          ? json['kalori']
          : int.tryParse(json['kalori']?.toString() ?? '0') ?? 0,
      carbs: (json['karbonhidrat'] is int)
          ? json['karbonhidrat']
          : int.tryParse(json['karbonhidrat']?.toString() ?? '0') ?? 0,
      protein: (json['protein'] is int)
          ? json['protein']
          : int.tryParse(json['protein']?.toString() ?? '0') ?? 0,
      fat: (json['yag'] is int)
          ? json['yag']
          : int.tryParse(json['yag']?.toString() ?? '0') ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'yemek': name,
      'kalori': calories,
      'karbonhidrat': carbs,
      'protein': protein,
      'yag': fat,
    };
  }
} 