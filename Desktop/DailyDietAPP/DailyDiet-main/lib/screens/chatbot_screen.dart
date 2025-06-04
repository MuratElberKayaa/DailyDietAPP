import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/diet_plan.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late ApiService _apiService;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initApiService();
  }

  Future<void> _initApiService() async {
    _apiService = await ApiService.getInstance();
  }

  Future<String?> _getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<Map<String, dynamic>?> _getProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = await _getUsername();
    if (username == null) return null;
    final data = prefs.getString('profileData_' + username);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  Future<void> _saveProfileData(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    final username = await _getUsername();
    if (username != null) {
      await prefs.setString('profileData_' + username, jsonEncode(profile));
    }
  }

  Map<String, dynamic> convertPlanToExpectedFormat(Map<String, dynamic> plan) {
    List<Map<String, dynamic>> ogunler = [];
    if (plan['kahvalti'] != null) {
      ogunler.add({'ogunAdi': 'Kahvaltı', 'yemekler': plan['kahvalti']});
    }
    if (plan['ogle'] != null) {
      ogunler.add({'ogunAdi': 'Öğle', 'yemekler': plan['ogle']});
    }
    if (plan['aksam'] != null) {
      ogunler.add({'ogunAdi': 'Akşam', 'yemekler': plan['aksam']});
    }
    if (plan['ara_ogun'] != null) {
      ogunler.add({'ogunAdi': 'Ara Öğün', 'yemekler': plan['ara_ogun']});
    }
    if (plan['su'] != null) {
      ogunler.add({'ogunAdi': 'Su', 'yemekler': plan['su']});
    }
    return {'ogunler': ogunler};
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final message = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(text: 'Siz: $message', isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _messageController.clear();

    try {
      // Profil verisini oku
      final profileData = await _getProfileData();
      Map<String, dynamic>? inputs;
      if (profileData != null) {
        inputs = {
          'isim': profileData['isim'],
          'yas': profileData['yas'],
          'boy': profileData['boy'],
          'kilo': profileData['kilo'],
          'hedef': profileData['hedef'],
          'diyet_tipi': profileData['diyet_tipi'],
        };
      }
      final response = await _apiService.sendDirectDifyMessage(message, inputs: inputs);
      print('DIFY RAW RESPONSE: ' + response.toString());
      String cleaned = response.replaceAll('```json', '').replaceAll('```', '').trim();
      Map<String, dynamic>? json;
      try {
        if (cleaned.startsWith('{')) {
          final decoded = jsonDecode(cleaned);
          if (decoded is Map) {
            json = Map<String, dynamic>.from(decoded);
          }
        }
      } catch (_) {
        json = null;
      }
      if (json == null) {
        setState(() {
          _messages.add(ChatMessage(text: 'Bot: $cleaned', isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        return;
      }
      // Buradan sonra json kesinlikle null değildir!
      final safeJson = json!;
      if (safeJson['answer'] is String && (safeJson['answer'] as String).trim().startsWith('{')) {
        try {
          final innerDecoded = jsonDecode(safeJson['answer']);
          if (innerDecoded is Map) {
            json = Map<String, dynamic>.from(innerDecoded);
          }
        } catch (_) {
          // inner parse edilemiyorsa, json olduğu gibi kalır
        }
      }
      final username = await _getUsername();
      if (username == null) {
        setState(() {
          _messages.add(ChatMessage(text: 'Bot: Kullanıcı adı bulunamadı, lütfen tekrar giriş yapın.', isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        return;
      }
      if (json!['data'] is Map && json!['data']['profil'] != null) {
        await _saveProfileData(json!['data']['profil']);
      }
      dynamic planToSave;
      if (json!['data'] is Map && json!['data']['diyet_listesi'] != null) {
        planToSave = json!['data']['diyet_listesi'];
      }
      if (planToSave != null && planToSave is Map && planToSave.isNotEmpty) {
        final planMap = Map<String, dynamic>.from(planToSave);
        final prefs = await SharedPreferences.getInstance();
        final formattedPlan = convertPlanToExpectedFormat(planMap);
        final dietPlan = DietPlan.fromJson(formattedPlan);
        print('Backend\'e kaydedilecek plan: ' + dietPlan.toJsonString());
        await prefs.setString('dietPlanData_' + username, dietPlan.toJsonString());
        final today = DateTime.now().toIso8601String().split('T')[0];
        await prefs.setString('dietPlanLastUpdate_' + username, today);
        // --- BACKEND'E KAYDET ---
        final userIdString = prefs.getString('userId');
        final userId = int.tryParse(userIdString ?? '') ?? 0;
        if (userId != 0) {
          try {
            await _apiService.saveDietPlanToServer(userId, dietPlan.toJsonString());
            print('Plan backend\'e başarıyla kaydedildi!');
          } catch (e) {
            print('Plan backend\'e kaydedilemedi: ' + e.toString());
          }
        }
        // ------------------------
        String botMessage = (json!['answer'] is String)
            ? json!['answer']
            : 'Diyet planınız hazır! Detayları "Diyet Planını Görüntüle" sekmesinden görebilirsiniz.';
        setState(() {
          _messages.add(ChatMessage(text: 'Bot: $botMessage', isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        return;
      } else {
        print('Dify cevabından plan ayıklanamadı veya boş. Backend\'e kaydedilmeyecek.');
        String botMessage = (json!['answer'] is String)
            ? json!['answer']
            : 'Diyet planı oluşturulamadı veya henüz hazır değil. Lütfen tekrar deneyin.';
        setState(() {
          _messages.add(ChatMessage(text: 'Bot: $botMessage', isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'Bot: Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.', isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
      print('Hata: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.green.shade400 : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? Colors.green.shade600 : Colors.grey.shade400,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 20,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diyet Asistanı'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _buildAvatar(false),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Yazıyor...'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}