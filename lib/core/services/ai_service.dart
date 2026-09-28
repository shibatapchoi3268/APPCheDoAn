import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Hàm gửi tin nhắn text tới AI (Gemini)
Future<String> askAiDietitian(String userMessage) async {
  final String apiUrl = 'http://10.0.2.2:8000/api/chat';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"question": userMessage}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return responseData['answer'] ?? "🥑 Bơ chưa nghĩ ra câu trả lời cho câu này, bạn thử hỏi khác đi nhé!";
    } else {
      return "🥑 Bơ xin lỗi, máy chủ AI đang bận một chút. Bạn thử lại sau nhé!";
    }
  } catch (e) {
    return "🥑 Kết nối bị gián đoạn rồi. Bạn kiểm tra mạng giúp Bơ nhé!";
  }
}

/// Hàm gửi ảnh món ăn tới AI (LLaVA + LoRA) để phân tích dinh dưỡng
Future<String> analyzeFoodImage(File imageFile) async {
  // Đã khớp đường dẫn với api_server.py
  final String apiUrl = 'https://unmarrying-uninterwoven-jacque.ngrok-free.dev/api/predict_calories';

  try {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Đã đổi tên trường thành 'file' để khớp với tham số UploadFile bên Python
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      // Trả về đoạn text miêu tả calo từ AI qua trường 'calories_info'
      return data['calories_info'] ?? "🥑 Bơ không nhận diện được món này, bạn chụp rõ hơn được không?";
    } else {
      return "🥑 Lỗi từ máy chủ (${response.statusCode}). Bơ đang cố gắng khắc phục!";
    }
  } catch (e) {
    print("Lỗi phân tích ảnh: $e");
    return "🥑 Không thể kết nối tới máy chủ. Bạn kiểm tra mạng cùng Bơ nhé!";
  }
}
