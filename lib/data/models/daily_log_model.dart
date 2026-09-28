import 'food_model.dart';

class DailyLogModel {
  final String date; // YYYY-MM-DD
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int waterIntake; // Tính bằng ml
  final List<FoodModel> breakfast;
  final List<FoodModel> lunch;
  final List<FoodModel> dinner;
  final List<FoodModel> snacks;

  DailyLogModel({
    required this.date,
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    this.waterIntake = 0,
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
    this.snacks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'waterIntake': waterIntake,
      'breakfast': breakfast.map((e) => e.toMap()).toList(),
      'lunch': lunch.map((e) => e.toMap()).toList(),
      'dinner': dinner.map((e) => e.toMap()).toList(),
      'snacks': snacks.map((e) => e.toMap()).toList(),
    };
  }

  factory DailyLogModel.fromMap(Map<String, dynamic> map) {
    return DailyLogModel(
      date: map['date'] ?? '',
      totalCalories: map['totalCalories']?.toDouble() ?? 0.0,
      totalProtein: map['totalProtein']?.toDouble() ?? 0.0,
      totalCarbs: map['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: map['totalFat']?.toDouble() ?? 0.0,
      waterIntake: map['waterIntake']?.toInt() ?? 0,
      breakfast: (map['breakfast'] as List? ?? [])
          .map((e) => FoodModel.fromMap(e, ''))
          .toList(),
      lunch: (map['lunch'] as List? ?? [])
          .map((e) => FoodModel.fromMap(e, ''))
          .toList(),
      dinner: (map['dinner'] as List? ?? [])
          .map((e) => FoodModel.fromMap(e, ''))
          .toList(),
      snacks: (map['snacks'] as List? ?? [])
          .map((e) => FoodModel.fromMap(e, ''))
          .toList(),
    );
  }
}
