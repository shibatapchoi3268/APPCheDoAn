import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Bảng màu "Quả Bơ" đồng bộ
  static const Color avocadoSkin = Color(0xFF388E3C);
  static const Color avocadoFlesh = Color(0xFFDCEDC8);
  static const Color avocadoDarkFlesh = Color(0xFF8BC34A);
  static const Color avocadoCream = Color(0xFFF1F8E9);

  // Form Fields
  String _gender = 'Nam';
  double _age = 25;
  double _weight = 70.0;
  double _height = 170.0;
  String _goal = 'maintain';
  String _activityLevel = 'moderate';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submit() async {
    setState(() => _isSaving = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final uid = authService.user!.uid;

      double bmr;
      if (_gender == 'Nam') {
        bmr = 10 * _weight + 6.25 * _height - 5 * _age + 5;
      } else {
        bmr = 10 * _weight + 6.25 * _height - 5 * _age - 161;
      }

      double multiplier = 1.2;
      switch (_activityLevel) {
        case 'sedentary': multiplier = 1.2; break;
        case 'light': multiplier = 1.375; break;
        case 'moderate': multiplier = 1.55; break;
        case 'active': multiplier = 1.725; break;
        case 'very_active': multiplier = 1.9; break;
      }

      double tdee = bmr * multiplier;
      double dailyGoal = tdee;
      if (_goal == 'lose') dailyGoal -= 500;
      if (_goal == 'gain') dailyGoal += 500;

      final newUser = UserModel(
        uid: uid,
        email: authService.user!.email!,
        age: _age.toInt(),
        weight: _weight,
        height: _height,
        gender: _gender,
        goal: _goal == 'lose' ? 'Giảm cân' : (_goal == 'gain' ? 'Tăng cơ' : 'Giữ dáng'),
        tdee: tdee,
        dailyCalorieGoal: dailyGoal,
        macros: {
          'carbs': (dailyGoal * 0.5) / 4,
          'protein': (dailyGoal * 0.25) / 4,
          'fat': (dailyGoal * 0.25) / 9,
        },
      );

      await firestoreService.saveUser(newUser);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu thông tin: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: avocadoCream,
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🥑', style: TextStyle(fontSize: 80)),
                  SizedBox(height: 20),
                  CircularProgressIndicator(color: avocadoSkin),
                  SizedBox(height: 20),
                  Text(
                    'Trợ lý Bơ đang chuẩn bị kế hoạch cho bạn...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: avocadoSkin, fontSize: 16),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: Container(
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index <= _currentPage ? avocadoSkin : avocadoFlesh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bước ${_currentPage + 1} / 3',
                    style: TextStyle(fontWeight: FontWeight.bold, color: avocadoSkin.withOpacity(0.7)),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        _buildPage1(),
                        _buildPage2(),
                        _buildPage3(),
                      ],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Về bản thân bạn 🥑', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: avocadoSkin)),
          const SizedBox(height: 8),
          const Text('Bơ cần biết giới tính và tuổi của bạn để tính toán chính xác.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 40),
          const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: avocadoSkin)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildGenderCard('Nam', Icons.male, Colors.blue),
              const SizedBox(width: 20),
              _buildGenderCard('Nữ', Icons.female, Colors.pink),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Độ tuổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: avocadoSkin)),
              Text('${_age.toInt()} tuổi', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: avocadoDarkFlesh)),
            ],
          ),
          Slider(
            value: _age,
            min: 10,
            max: 80,
            divisions: 70,
            activeColor: avocadoSkin,
            inactiveColor: avocadoFlesh,
            onChanged: (val) => setState(() => _age = val),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String label, IconData icon, Color color) {
    bool isSelected = _gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected ? avocadoFlesh : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isSelected ? avocadoSkin : Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 50, color: isSelected ? avocadoSkin : Colors.grey),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? avocadoSkin : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chỉ số cơ thể 📏', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: avocadoSkin)),
          const SizedBox(height: 8),
          const Text('Kéo thanh trượt để chọn chiều cao và cân nặng hiện tại.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 40),
          _buildMetricSlider('Chiều cao', _height, 100, 220, 'cm', (val) => setState(() => _height = val)),
          const SizedBox(height: 40),
          _buildMetricSlider('Cân nặng', _weight, 30, 150, 'kg', (val) => setState(() => _weight = val)),
        ],
      ),
    );
  }

  Widget _buildMetricSlider(String label, double value, double min, double max, String unit, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: avocadoSkin)),
            Text('${value.toInt()} $unit', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: avocadoDarkFlesh)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: avocadoSkin,
          inactiveColor: avocadoFlesh,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mục tiêu của bạn 🎯', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: avocadoSkin)),
          const SizedBox(height: 8),
          const Text('Dựa vào đây, Trợ lý Bơ sẽ tính toán lượng Calo hàng ngày.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 32),
          _buildGoalOption('lose', 'Giảm cân', 'Đốt mỡ và thon gọn vóc dáng', Icons.trending_down),
          const SizedBox(height: 16),
          _buildGoalOption('maintain', 'Giữ dáng', 'Duy trì cơ thể khỏe mạnh', Icons.favorite_border),
          const SizedBox(height: 16),
          _buildGoalOption('gain', 'Tăng cơ', 'Xây dựng cơ bắp săn chắc', Icons.fitness_center),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String value, String title, String subtitle, IconData icon) {
    bool isSelected = _goal == value;
    return GestureDetector(
      onTap: () => setState(() => _goal = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? avocadoFlesh : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? avocadoSkin : Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? Colors.white : avocadoCream, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: isSelected ? avocadoSkin : Colors.grey),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? avocadoSkin : Colors.black87)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: avocadoSkin),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            GestureDetector(
              onTap: _prevPage,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.arrow_back_ios_new, color: avocadoSkin),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: avocadoSkin,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
              child: Text(
                _currentPage == 2 ? 'BẮT ĐẦU NGAY 🥑' : 'TIẾP THEO',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
