import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/daily_log_model.dart';
import '../../../data/models/food_model.dart';
import '../../../data/models/user_model.dart';
import '../food/manual_add_food_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Tông màu "Quả Bơ" (Avocado Theme) đồng bộ
  static const Color avocadoSkin = Color(0xFF388E3C);
  static const Color avocadoFlesh = Color(0xFFDCEDC8);
  static const Color avocadoDarkFlesh = Color(0xFF8BC34A);
  static const Color avocadoCream = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String uid = authService.user!.uid;

    return Scaffold(
      backgroundColor: avocadoCream,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🥑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Dinh dưỡng hôm nay', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: avocadoSkin,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel>(
        stream: firestoreService.streamUser(uid),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          
          return StreamBuilder<DailyLogModel>(
            stream: firestoreService.streamDailyLog(uid, today),
            builder: (context, logSnapshot) {
              if (logSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: avocadoDarkFlesh));
              }

              final log = logSnapshot.data ?? DailyLogModel(date: today);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalorieCard(context, log, user),
                    const SizedBox(height: 24),
                    _buildMacroSection(context, log, user),
                    const SizedBox(height: 24),
                    _buildWaterTrackingSection(context, uid, log),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('🍱', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        const Text(
                          'Nhật ký ăn uống',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: avocadoSkin),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMealList(context, log),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildCalorieCard(BuildContext context, DailyLogModel log, UserModel? user) {
    double target = user?.dailyCalorieGoal ?? 2000;
    double consumed = log.totalCalories;
    double remaining = target - consumed;
    double percent = consumed / target;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: avocadoSkin.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 65.0,
            lineWidth: 12.0,
            percent: percent > 1.0 ? 1.0 : (percent < 0 ? 0 : percent),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  remaining > 0 ? remaining.toInt().toString() : '0',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: avocadoSkin),
                ),
                const Text('còn lại', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            progressColor: avocadoDarkFlesh,
            backgroundColor: avocadoFlesh.withOpacity(0.5),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalorieStat('Mục tiêu', target.toInt().toString(), Colors.blue.shade700),
                const SizedBox(height: 16),
                _buildCalorieStat('Đã nạp', consumed.toInt().toString(), Colors.orange.shade700),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCalorieStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(
          '$value kcal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
        ),
      ],
    );
  }

  Widget _buildMacroSection(BuildContext context, DailyLogModel log, UserModel? user) {
    double proteinTarget = user?.macros?['protein'] ?? 150;
    double carbsTarget = user?.macros?['carbs'] ?? 250;
    double fatTarget = user?.macros?['fat'] ?? 70;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroIndicator('Carbs', log.totalCarbs, carbsTarget, Colors.blue.shade400),
          _buildMacroIndicator('Protein', log.totalProtein, proteinTarget, avocadoDarkFlesh),
          _buildMacroIndicator('Fat', log.totalFat, fatTarget, Colors.orange.shade400),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(String label, double current, double target, Color color) {
    double percent = current / target;
    return Column(
      children: [
        LinearPercentIndicator(
          width: 90.0,
          lineHeight: 8.0,
          percent: percent > 1.0 ? 1.0 : (percent < 0 ? 0 : percent),
          progressColor: color,
          backgroundColor: color.withOpacity(0.1),
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
          animation: true,
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text('${current.toInt()}g / ${target.toInt()}g', style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildWaterTrackingSection(BuildContext context, String uid, DailyLogModel log) {
    final int waterGoal = 2000;
    final int totalGlasses = (waterGoal / 100).ceil();
    final int currentWater = log.waterIntake;
    final int filledGlasses = currentWater ~/ 100;
    final int partialGlassAmount = currentWater % 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Uống nước 💧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$currentWater / $waterGoal ml', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
                onPressed: () => _showAddWaterDialog(context, uid, log),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(totalGlasses > 12 ? 12 : totalGlasses, (index) {
              bool isFirst = index == 0;
              double waterLevel = 0.0;
              if (index < filledGlasses) {
                waterLevel = 1.0;
              } else if (index == filledGlasses) {
                waterLevel = partialGlassAmount / 100.0;
              }

              return GestureDetector(
                onTap: () => _quickAddWater(context, uid, log, 100),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 50,
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8), top: Radius.circular(4)),
                        border: Border.all(color: Colors.blue.shade200, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FractionallySizedBox(
                        heightFactor: waterLevel,
                        child: Container(width: double.infinity, color: Colors.blue.shade400.withOpacity(0.8)),
                      ),
                    ),
                    if (isFirst && waterLevel < 1.0)
                      const Icon(Icons.add, color: Colors.blue, size: 16),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMealList(BuildContext context, DailyLogModel log) {
    final List<Map<String, dynamic>> mealData = [
      {'name': 'Bữa sáng', 'icon': Icons.wb_sunny_rounded, 'foods': log.breakfast},
      {'name': 'Bữa trưa', 'icon': Icons.wb_cloudy_rounded, 'foods': log.lunch},
      {'name': 'Bữa tối', 'icon': Icons.nightlight_round, 'foods': log.dinner},
      {'name': 'Ăn vặt', 'icon': Icons.apple_rounded, 'foods': log.snacks},
    ];

    return Column(
      children: mealData.map((meal) {
        final List<FoodModel> foods = meal['foods'] as List<FoodModel>;
        final String foodNames = foods.map((f) => f.name).join(', ');
        final double calories = foods.fold(0.0, (sum, item) => sum + item.calories);
        final double protein = foods.fold(0.0, (sum, item) => sum + item.protein);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: avocadoFlesh.withOpacity(0.4), shape: BoxShape.circle),
              child: Icon(meal['icon'] as IconData, color: avocadoSkin),
            ),
            title: Text(
              foodNames.isEmpty ? (meal['name'] as String) : foodNames,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: foodNames.isEmpty ? Colors.grey.shade400 : Colors.black87,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                foodNames.isEmpty 
                  ? 'Bấm để chọn món' 
                  : '${meal['name']} • ${calories.toInt()} kcal • ${protein.toInt()}g Đạm',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            trailing: const Icon(Icons.add_circle_outline_rounded, color: avocadoSkin),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ManualAddFoodScreen(category: meal['name'] as String)));
            },
          ),
        );
      }).toList(),
    );
  }

  void _quickAddWater(BuildContext context, String uid, DailyLogModel log, int amount) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final updatedLog = DailyLogModel(
      date: log.date,
      totalCalories: log.totalCalories,
      totalProtein: log.totalProtein,
      totalCarbs: log.totalCarbs,
      totalFat: log.totalFat,
      waterIntake: log.waterIntake + amount,
      breakfast: log.breakfast,
      lunch: log.lunch,
      dinner: log.dinner,
      snacks: log.snacks,
    );
    await firestoreService.saveDailyLog(uid, updatedLog);
  }

  void _showAddWaterDialog(BuildContext context, String uid, DailyLogModel log) {
    final controller = TextEditingController(text: '250');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lượng nước (ml)', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nhập số ml...',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              int val = int.tryParse(controller.text) ?? 0;
              if (val > 0) _quickAddWater(context, uid, log, val);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
