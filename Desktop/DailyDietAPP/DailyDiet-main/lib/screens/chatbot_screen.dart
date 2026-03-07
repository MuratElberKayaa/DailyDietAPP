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
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = await _getUsername();
      if (username == null) {
        print('Kullanıcı adı bulunamadı');
        return null;
      }
      
      // Önce SharedPreferences'dan kontrol et
      final data = prefs.getString('profileData_' + username);
      if (data != null) {
        return jsonDecode(data);
      }

      // Eğer SharedPreferences'da yoksa, API'den al
      final userId = prefs.getString('userId');
      if (userId == null) {
        print('Kullanıcı ID bulunamadı');
        return null;
      }

      final apiService = await ApiService.getInstance();
      final profileResponse = await apiService.getUserProfile(int.parse(userId));
      if (profileResponse != null) {
        // Profil verilerini SharedPreferences'a kaydet
        await _saveProfileData(profileResponse);
        return profileResponse;
      }
      
      return null;
    } catch (e) {
      print('Profil verisi alınırken hata oluştu: $e');
      return null;
    }
  }

  Future<void> _saveProfileData(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = await _getUsername();
      if (username != null) {
        await prefs.setString('profileData_' + username, jsonEncode(profile));
        print('Profil verisi kaydedildi: $profile');
      }
    } catch (e) {
      print('Profil verisi kaydedilirken hata oluştu: $e');
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
          'isim': profileData['isim'] ?? '',
          'yas': profileData['yas'] ?? 0,
          'boy': profileData['boy'] ?? 0,
          'kilo': profileData['kilo'] ?? 0,
          'hedef': profileData['hedef'] ?? '',
          'diyet_tipi': profileData['diyet_tipi'] ?? '',
          'allowed_calories': profileData['allowedCalories'] ?? 2000,
        };
      } else {
        print('Profil verisi bulunamadı, varsayılan değerler kullanılacak');
        inputs = {
          'allowed_calories': 2000,
        };
      }

      print('DIFY API\'ye gönderilecek inputs: $inputs');
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
      } catch (e) {
        print('JSON parse hatası: $e');
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
        } catch (e) {
          print('İç JSON parse hatası: $e');
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
            print('Plan backend\'e kaydedilemedi: $e');
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
      print('Chatbot hatası: $e');
      String errorMessage = 'Üzgünüm, bir hata oluştu. ';
      if (e.toString().contains('SocketException')) {
        errorMessage += 'İnternet bağlantınızı kontrol edin.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage += 'Sunucu yanıt vermedi, lütfen tekrar deneyin.';
      } else {
        errorMessage += 'Lütfen tekrar deneyin.';
      }
      setState(() {
        _messages.add('Bot: $errorMessage');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true, // En son mesajlar altta görünecek
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - 1 - index];
                  final isUser = message.startsWith('Siz:');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: isUser ? Colors.black87 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
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
    super.dispose();
  }
}