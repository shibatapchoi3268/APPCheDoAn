class FoodModel {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl;
  final String? category; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'

  FoodModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map, String docId) {
    return FoodModel(
      id: docId,
      name: map['name'] ?? '',
      calories: map['calories']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
      category: map['category'],
    );
  }
}
