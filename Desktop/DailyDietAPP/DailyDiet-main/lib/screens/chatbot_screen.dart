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
  final List<String> _messages = [];
  bool _isLoading = false;
  late ApiService _apiService;

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
      _messages.add('Siz: $message');
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
          _messages.add('Bot: $cleaned');
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
          _messages.add('Bot: Kullanıcı adı bulunamadı, lütfen tekrar giriş yapın.');
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
          _messages.add('Bot: $botMessage');
          _isLoading = false;
        });
        return;
      } else {
        print('Dify cevabından plan ayıklanamadı veya boş. Backend\'e kaydedilmeyecek.');
        String botMessage = (json!['answer'] is String)
            ? json!['answer']
            : 'Diyet planı oluşturulamadı veya henüz hazır değil. Lütfen tekrar deneyin.';
        setState(() {
          _messages.add('Bot: $botMessage');
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _messages.add('Bot: Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.');
        _isLoading = false;
      });
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}