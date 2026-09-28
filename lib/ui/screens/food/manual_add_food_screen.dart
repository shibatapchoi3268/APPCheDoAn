import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/food_database_service.dart';
import '../../../data/models/food_model.dart';
import '../../../data/models/daily_log_model.dart';

class ManualAddFoodScreen extends StatefulWidget {
  final String category;
  const ManualAddFoodScreen({super.key, required this.category});

  @override
  State<ManualAddFoodScreen> createState() => _ManualAddFoodScreenState();
}

class _ManualAddFoodScreenState extends State<ManualAddFoodScreen> {
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  final _dbService = FoodDatabaseService();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  bool _isSaving = false;
  bool _isSearching = false;

  // Tông màu "Quả Bơ" đồng bộ
  static const Color avocadoSkin = Color(0xFF388E3C);
  static const Color avocadoFlesh = Color(0xFFDCEDC8);
  static const Color avocadoDarkFlesh = Color(0xFF8BC34A);
  static const Color avocadoCream = Color(0xFFF1F8E9);

  @override
  void dispose() {
    _nameController.dispose();
    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      final results = await _dbService.searchFood(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  void _selectFood(Map<String, dynamic> food) {
    setState(() {
      _nameController.text = food['name'] ?? '';
      _calController.text = food['calories']?.toString() ?? '';
      _proteinController.text = food['protein']?.toString() ?? '';
      _carbsController.text = food['carbs']?.toString() ?? '';
      _fatController.text = food['fat']?.toString() ?? '';
      _searchResults = []; // Ẩn kết quả sau khi chọn
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveFood() async {
    if (_nameController.text.isEmpty || _calController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🥑 Bạn điền tên món và calo giúp Bơ nhé!'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final String uid = authService.user!.uid;
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final newFood = FoodModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        calories: double.tryParse(_calController.text) ?? 0.0,
        protein: double.tryParse(_proteinController.text) ?? 0.0,
        carbs: double.tryParse(_carbsController.text) ?? 0.0,
        fat: double.tryParse(_fatController.text) ?? 0.0,
        category: widget.category,
      );

      final currentLog = await firestoreService.streamDailyLog(uid, today).first;

      List<FoodModel> breakfast = List.from(currentLog.breakfast);
      List<FoodModel> lunch = List.from(currentLog.lunch);
      List<FoodModel> dinner = List.from(currentLog.dinner);
      List<FoodModel> snacks = List.from(currentLog.snacks);

      if (widget.category == 'Bữa sáng') {
        breakfast.add(newFood);
      } else if (widget.category == 'Bữa trưa') {
        lunch.add(newFood);
      } else if (widget.category == 'Bữa tối') {
        dinner.add(newFood);
      } else {
        snacks.add(newFood);
      }

      final updatedLog = DailyLogModel(
        date: today,
        totalCalories: currentLog.totalCalories + newFood.calories,
        totalProtein: currentLog.totalProtein + newFood.protein,
        totalCarbs: currentLog.totalCarbs + newFood.carbs,
        totalFat: currentLog.totalFat + newFood.fat,
        waterIntake: currentLog.waterIntake,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        snacks: snacks,
      );

      await firestoreService.saveDailyLog(uid, updatedLog);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🥑 Đã thêm món ăn vào nhật ký!'), backgroundColor: avocadoSkin),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: avocadoCream,
      appBar: AppBar(
        title: Text('Thêm vào ${widget.category}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: avocadoSkin,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tìm kiếm món ăn 🔍',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: avocadoSkin),
            ),
            const SizedBox(height: 16),
            
            // Ô tìm kiếm món ăn từ cơ sở dữ liệu CSV đã upload
            TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Nhập tên món ăn (ví dụ: Phở, Bánh mì...)',
                prefixIcon: const Icon(Icons.search_rounded, color: avocadoSkin),
                suffixIcon: _isSearching ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: avocadoSkin),
                ) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            // Danh sách kết quả tìm kiếm
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final food = _searchResults[index];
                    return ListTile(
                      title: Text(food['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${food['calories']} kcal | Đạm: ${food['protein']}g'),
                      trailing: const Icon(Icons.add_circle_outline, color: avocadoSkin),
                      onTap: () => _selectFood(food),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Text(
              'Thông tin chi tiết 📝',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: avocadoSkin),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildInputField(_nameController, 'Tên món ăn', Icons.restaurant_rounded, null),
                  const SizedBox(height: 16),
                  _buildInputField(_calController, 'Lượng Calo (kcal)', Icons.local_fire_department_rounded, Colors.orange, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMacroField(_proteinController, 'Đạm (g)', Icons.fitness_center_rounded, Colors.redAccent),
                      const SizedBox(width: 12),
                      _buildMacroField(_carbsController, 'Tinh bột (g)', Icons.grain_rounded, Colors.blueAccent),
                      const SizedBox(width: 12),
                      _buildMacroField(_fatController, 'Béo (g)', Icons.opacity_rounded, Colors.orangeAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveFood,
              style: ElevatedButton.styleFrom(
                backgroundColor: avocadoSkin,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('XÁC NHẬN THÊM 🥑', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, Color? iconColor, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor ?? avocadoSkin),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: avocadoCream.withOpacity(0.5),
      ),
    );
  }

  Widget _buildMacroField(TextEditingController controller, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: color.withOpacity(0.1),
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
