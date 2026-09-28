import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class FoodDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Đọc file CSV từ assets và tải lên Firestore collection 'foods'
  Future<void> uploadCsvToFirestore(String assetPath) async {
    try {
      // 1. Tải nội dung file CSV
      final String rawCsv = await rootBundle.loadString(assetPath);
      
      // 2. Chuyển đổi CSV sang danh sách
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(rawCsv);
      
      if (rowsAsListOfValues.isEmpty) return;

      // Giả sử dòng đầu tiên là tiêu đề (name, calories, fat, carbs, protein)
      final dataRows = rowsAsListOfValues.sublist(1);

      // 3. Sử dụng Batch để tối ưu hóa việc ghi dữ liệu (tối đa 500 docs/lần)
      WriteBatch batch = _db.batch();
      int count = 0;

      for (var row in dataRows) {
        if (row.length < 5) continue;

        String name = row[0].toString().trim();
        double calories = double.tryParse(row[1].toString()) ?? 0.0;
        double fat = double.tryParse(row[2].toString()) ?? 0.0;
        double carbs = double.tryParse(row[3].toString()) ?? 0.0;
        double protein = double.tryParse(row[4].toString()) ?? 0.0;

        DocumentReference docRef = _db.collection('foods').doc(); // ID tự động
        
        batch.set(docRef, {
          'name': name,
          'calories': calories,
          'fat': fat,
          'carbs': carbs,
          'protein': protein,
          'searchName': name.toLowerCase(), // Hỗ trợ tìm kiếm không phân biệt hoa thường
        });

        count++;
        if (count == 500) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
      
      print("🥑 Đã đẩy thành công dữ liệu từ CSV lên Firebase!");
    } catch (e) {
      print("❌ Lỗi khi tải dữ liệu: $e");
    }
  }

  /// Tìm kiếm món ăn theo tên từ Firestore
  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    if (query.isEmpty) return [];
    
    final queryLower = query.toLowerCase();
    
    final snapshot = await _db.collection('foods')
        .where('searchName', isGreaterThanOrEqualTo: queryLower)
        .where('searchName', isLessThanOrEqualTo: '$queryLower\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
