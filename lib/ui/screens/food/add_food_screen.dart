import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/daily_log_model.dart';
import '../../../data/models/food_model.dart';

class AddFoodScreen extends StatefulWidget {
  final String category;
  const AddFoodScreen({super.key, required this.category});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  // Bảng màu "Quả Bơ" (Avocado Theme) đồng bộ
  static const Color avocadoSkin = Color(0xFF388E3C);
  static const Color avocadoFlesh = Color(0xFFDCEDC8);
  static const Color avocadoDarkFlesh = Color(0xFF8BC34A);
  static const Color avocadoCream = Color(0xFFF1F8E9);

  File? _image;
  final _picker = ImagePicker();
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _aiAnalysisResult;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isAnalyzing = true;
          _aiAnalysisResult = null;
        });
        
        // Gọi API thực tế trả về chuỗi text miêu tả calo từ data['calories_info']
        final dynamic result = await analyzeFoodImage(_image!);
        
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            if (result is String && result.isNotEmpty) {
              _aiAnalysisResult = result;
            } else {
              _aiAnalysisResult = '🥑 Bơ không nhận diện được phản hồi hợp lệ từ máy chủ.';
            }
          });
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi quét ảnh: $e'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  '🥑 Chọn nguồn ảnh',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: avocadoSkin),
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: avocadoFlesh, shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: avocadoSkin),
                ),
                title: const Text('Thư viện ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.photo_camera_rounded, color: Colors.orange.shade800),
                ),
                title: const Text('Máy ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm bóc tách thông tin từ chuỗi văn bản của AI
  Map<String, double> _parseNutrition(String text) {
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    
    // Xóa dấu tiếng Việt và chuyển về chữ thường để dễ so khớp
    String cleanText = text.toLowerCase();
    
    // Tìm calo: số đứng trước hoặc sau kcal, calo, calories
    final calMatch = RegExp(r'(\d+)\s*(kcal|calo|calories|năng lượng)', caseSensitive: false).firstMatch(cleanText);
    if (calMatch != null) calories = double.tryParse(calMatch.group(1)!) ?? 0;
    
    // Tìm protein: số đứng cạnh từ protein, đạm
    final proteinMatch = RegExp(r'(protein|đạm|p):\s*(\d+)', caseSensitive: false).firstMatch(cleanText);
    if (proteinMatch != null) protein = double.tryParse(proteinMatch.group(2)!) ?? 0;
    
    // Tìm carbs: số đứng cạnh từ carb, tinh bột
    final carbsMatch = RegExp(r'(carbs?|tinh bột|c):\s*(\d+)', caseSensitive: false).firstMatch(cleanText);
    if (carbsMatch != null) carbs = double.tryParse(carbsMatch.group(2)!) ?? 0;
    
    // Tìm fat: số đứng cạnh từ fat, béo
    final fatMatch = RegExp(r'(fat|béo|f):\s*(\d+)', caseSensitive: false).firstMatch(cleanText);
    if (fatMatch != null) fat = double.tryParse(fatMatch.group(2)!) ?? 0;

    return {'cal': calories, 'p': protein, 'c': carbs, 'f': fat};
  }

  void _showMealPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: [
              const Center(child: Text('🍱 Chọn bữa ăn muốn thêm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: avocadoSkin))),
              const SizedBox(height: 30),
              _mealOption('Bữa sáng', Icons.wb_sunny_rounded),
              _mealOption('Bữa trưa', Icons.wb_cloudy_rounded),
              _mealOption('Bữa tối', Icons.nightlight_round),
              _mealOption('Ăn vặt', Icons.apple_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: avocadoSkin),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context);
        _saveToDiary(title);
      },
    );
  }

  Future<void> _saveToDiary(String mealCategory) async {
    if (_aiAnalysisResult == null) return;

    setState(() => _isSaving = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final String uid = authService.user!.uid;
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final nutrition = _parseNutrition(_aiAnalysisResult!);
      
      final newFood = FoodModel(
        id: const Uuid().v4(),
        name: "Món ăn từ AI Scan",
        calories: nutrition['cal']!,
        protein: nutrition['p']!,
        carbs: nutrition['c']!,
        fat: nutrition['f']!,
        category: mealCategory,
      );

      final currentLog = await firestoreService.streamDailyLog(uid, today).first;

      List<FoodModel> b = List.from(currentLog.breakfast);
      List<FoodModel> l = List.from(currentLog.lunch);
      List<FoodModel> d = List.from(currentLog.dinner);
      List<FoodModel> s = List.from(currentLog.snacks);

      if (mealCategory == 'Bữa sáng') b.add(newFood);
      else if (mealCategory == 'Bữa trưa') l.add(newFood);
      else if (mealCategory == 'Bữa tối') d.add(newFood);
      else s.add(newFood);

      final updatedLog = DailyLogModel(
        date: today,
        totalCalories: currentLog.totalCalories + newFood.calories,
        totalProtein: currentLog.totalProtein + newFood.protein,
        totalCarbs: currentLog.totalCarbs + newFood.carbs,
        totalFat: currentLog.totalFat + newFood.fat,
        waterIntake: currentLog.waterIntake,
        breakfast: b,
        lunch: l,
        dinner: d,
        snacks: s,
      );

      await firestoreService.saveDailyLog(uid, updatedLog);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🥑 Đã thêm vào nhật ký dinh dưỡng!'), backgroundColor: avocadoSkin),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.redAccent),
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
        title: Row(
          children: [
            const Text('🥑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Quét Dinh Dưỡng AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: avocadoSkin,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khung chọn ảnh & trạng thái quét của LLaVA
            GestureDetector(
              onTap: _isAnalyzing || _isSaving ? null : () => _showImageSourceActionSheet(context),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: avocadoSkin.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                  image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                  border: Border.all(color: avocadoSkin.withOpacity(0.1), width: 2),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: avocadoFlesh.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, size: 48, color: avocadoSkin),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Chụp hoặc Tải ảnh món ăn',
                            style: TextStyle(color: avocadoSkin, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Trợ lý Bơ sẽ giúp bạn tính calo',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      )
                    : _isAnalyzing
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
                                  SizedBox(height: 20),
                                  Text(
                                    '🥑 Bơ đang phân tích...',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Chỉ mất vài giây thôi nhé',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Khung hiển thị văn bản kết quả phân tích
            if (_aiAnalysisResult != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: avocadoSkin.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🥑', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        const Text(
                          'Kết quả từ Trợ lý Bơ:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: avocadoSkin,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: avocadoFlesh, thickness: 1),
                    ),
                    Text(
                      _aiAnalysisResult!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _showMealPicker,
                icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_task_rounded),
                label: const Text('THÊM VÀO NHẬT KÝ 🥑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: avocadoSkin,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showImageSourceActionSheet(context),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('QUÉT LẠI MÓN KHÁC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: avocadoSkin,
                  side: const BorderSide(color: avocadoSkin, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
            
            // Hướng dẫn nhỏ khi chưa có ảnh
            if (_image == null && !_isAnalyzing) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: avocadoFlesh, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: Colors.orangeAccent),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Mẹo: Hãy chụp ảnh món ăn thật rõ nét để Bơ nhận diện chính xác nhất nhé!',
                        style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
