class UserModel {
  final String uid;
  final String email;
  final String? name;
  final int? age;
  final double? weight;
  final double? height;
  final String? gender;
  final String? goal; // 'lose', 'maintain', 'gain'
  final double? tdee;
  final double? dailyCalorieGoal;
  final Map<String, double>? macros; // {'carbs': 0, 'protein': 0, 'fat': 0}

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.goal,
    this.tdee,
    this.dailyCalorieGoal,
    this.macros,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'goal': goal,
      'tdee': tdee,
      'dailyCalorieGoal': dailyCalorieGoal,
      'macros': macros,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      age: map['age'],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      gender: map['gender'],
      goal: map['goal'],
      tdee: map['tdee']?.toDouble(),
      dailyCalorieGoal: map['dailyCalorieGoal']?.toDouble(),
      macros: map['macros'] != null ? Map<String, double>.from(map['macros']) : null,
    );
  }
}
