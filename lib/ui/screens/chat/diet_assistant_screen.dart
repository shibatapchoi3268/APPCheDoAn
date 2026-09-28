import 'package:flutter/material.dart';
import 'package:appchedoan/core/services/ai_service.dart';

class Message {
  final String text;
  final bool isUser;
  Message(this.text, this.isUser);
}

class DietAssistantScreen extends StatefulWidget {
  const DietAssistantScreen({super.key});

  @override
  State<DietAssistantScreen> createState() => _DietAssistantScreenState();
}

class _DietAssistantScreenState extends State<DietAssistantScreen> {
  // Bảng màu "Quả Bơ" (Avocado Theme)
  static const Color avocadoSkin = Color(0xFF388E3C);
  static const Color avocadoFlesh = Color(0xFFDCEDC8);
  static const Color avocadoDarkFlesh = Color(0xFF8BC34A);
  static const Color avocadoCream = Color(0xFFF1F8E9);
  static const Color avocadoPit = Color(0xFF795548);

  final List<Message> _messages = [
    Message("🥑 Xin chào! Tôi là trợ lý dinh dưỡng Bơ Xanh. Hôm nay bạn muốn tư vấn món gì nào?", false),
  ];
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    String userText = _controller.text;
    setState(() {
      _messages.add(Message(userText, true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Gọi AI Service thực tế
    final dynamic response = await askAiDietitian(userText);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(Message(response.toString(), false));
      });
      _scrollToBottom();
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
            const Text(
              'Trợ lý Bơ Xanh',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: avocadoSkin,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {
              _messages.clear();
              _messages.add(Message("🥑 Xin chào! Tôi là trợ lý dinh dưỡng Bơ Xanh. Hôm nay bạn muốn tư vấn món gì nào?", false));
            }),
          )
        ],
      ),
      body: Stack(
        children: [
          // Watermark quả bơ lớn ở giữa nền
          Center(
            child: Opacity(
              opacity: 0.05,
              child: const Text('🥑', style: TextStyle(fontSize: 250)),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: _messages.length <= 1 
                  ? _buildWelcomeUI() 
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildChatBubble(msg);
                      },
                    ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: avocadoDarkFlesh,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeUI() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🥑', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text(
              'Chào mừng bạn!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: avocadoSkin),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tôi là Trợ lý Bơ Xanh. Hãy hỏi tôi bất cứ điều gì về dinh dưỡng và chế độ ăn uống nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 30),
            _buildQuickQuery("Hôm nay ăn gì cho khỏe?"),
            _buildQuickQuery("Cách giảm cân hiệu quả?"),
            _buildQuickQuery("Calo trong quả bơ là bao nhiêu?"),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuery(String query) {
    return GestureDetector(
      onTap: () {
        _controller.text = query;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: avocadoDarkFlesh.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: avocadoDarkFlesh, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(query, style: const TextStyle(color: avocadoSkin, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(Message msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser)
            const CircleAvatar(
              radius: 18,
              backgroundColor: avocadoDarkFlesh,
              child: Text('🥑', style: TextStyle(fontSize: 18)),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isUser ? avocadoDarkFlesh : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(msg.isUser ? 20 : 0),
                      bottomRight: Radius.circular(msg.isUser ? 0 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (msg.isUser)
            const CircleAvatar(
              radius: 18,
              backgroundColor: avocadoSkin,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: avocadoCream,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi cho Bơ...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: avocadoSkin,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
