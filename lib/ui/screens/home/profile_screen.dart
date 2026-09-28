import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/food_database_service.dart';
import '../../../data/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Tông màu "Quả Bơ" (Avocado Theme) đồng bộ
  static const Color avocadoSkin = Color(0xFF388E3C);
  static const Color avocadoFlesh = Color(0xFFDCEDC8);
  static const Color avocadoDarkFlesh = Color(0xFF8BC34A);
  static const Color avocadoCream = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final foodDbService = FoodDatabaseService();

    return Scaffold(
      backgroundColor: avocadoCream,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Hồ sơ của bạn', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: avocadoSkin,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: authService.user == null
          ? const Center(child: CircularProgressIndicator(color: avocadoDarkFlesh))
          : StreamBuilder<UserModel>(
              stream: firestoreService.streamUser(authService.user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: avocadoDarkFlesh));
                }
                
                final user = snapshot.data;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const CircleAvatar(
                                radius: 55,
                                backgroundColor: avocadoFlesh,
                                child: Text('🥑', style: TextStyle(fontSize: 50)),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: avocadoSkin,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        user?.name ?? 'Người dùng Bơ',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: avocadoSkin),
                      ),
                      Text(
                        authService.user?.email ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      
                      // Bảng thông tin chỉ số
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildProfileItem(Icons.height, 'Chiều cao', '${user?.height?.toInt() ?? 0} cm', Colors.blue),
                            const Divider(height: 1, indent: 60),
                            _buildProfileItem(Icons.monitor_weight_outlined, 'Cân nặng', '${user?.weight?.toInt() ?? 0} kg', Colors.orange),
                            const Divider(height: 1, indent: 60),
                            _buildProfileItem(Icons.cake, 'Tuổi', '${user?.age ?? 0} tuổi', Colors.pink),
                            const Divider(height: 1, indent: 60),
                            _buildProfileItem(Icons.flag_rounded, 'Mục tiêu', user?.goal ?? 'Chưa đặt', Colors.red),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // Nút Import CSV dữ liệu món ăn
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Hiển thị loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator(color: avocadoSkin)),
                          );
                          
                          await foodDbService.uploadCsvToFirestore('assets/data/foods.csv');
                          
                          if (context.mounted) {
                            Navigator.pop(context); // Tắt loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🥑 Đã cập nhật cơ sở dữ liệu món ăn!'),
                                backgroundColor: avocadoSkin,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('CẬP NHẬT CƠ SỞ DỮ LIỆU MÓN ĂN', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: avocadoFlesh,
                          foregroundColor: avocadoSkin,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),

                      const SizedBox(height: 16),
                      
                      // Nút đăng xuất
                      ElevatedButton.icon(
                        onPressed: () => authService.signOut(),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('ĐĂNG XUẤT KHỎI BƠ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.redAccent,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.redAccent, width: 1),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Phiên bản 1.0.0 - Bơ AI Team',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value, Color iconColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: avocadoSkin),
      ),
    );
  }
}
