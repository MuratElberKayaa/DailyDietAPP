import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiService {
  static ApiService? _instance;
  static Future<ApiService> getInstance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = ApiService(prefs);
    return _instance!;
  }

  final SharedPreferences _prefs;
  final String _baseUrl = 'http://172.28.240.1:5001/api';
  final String _difyUrl = 'https://api.dify.ai/v1';
  final String _difyApiKey = 'app-dNj8ge94nfEGHGivm2e2BZMP';
  String? _token;

  ApiService(this._prefs) {
    _token = _prefs.getString('token');
  }

  // Login işlemi
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Login attempt for email: $email');
      print('Using base URL: $_baseUrl');
      
      final loginUrl = Uri.parse('$_baseUrl/Authentication/login');
      print('Full login URL: $loginUrl');
      
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'email': email,
        'password': password,
      });
      
      print('Request headers: $headers');
      print('Request body: $body');
      
      final response = await http.post(
        loginUrl,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login successful, token received');
        await saveToken(data['token']);
        await _prefs.setString('username', email);
        
        if (data['userId'] != null) {
          print('User ID from response: ${data['userId']}');
          await _prefs.setString('userId', data['userId'].toString());
        } else {
          print('No userId in response, getting from getUserId()');
          await getUserId();
        }
        
        // GİRİŞ BAŞARILI: Eski diyet planı verilerini temizle
        await _prefs.remove('dietPlan');
        await _prefs.remove('dietPlanData_' + email);
        await _prefs.remove('dietPlanLastUpdate_' + email);
        await _prefs.remove('lastUpdateDate');
        return data;
      } else {
        print('Login failed with status code: ${response.statusCode}');
        print('Error response: ${response.body}');
        throw Exception('Login failed: Status ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('Login error occurred: $e');
      if (e is TimeoutException) {
        throw Exception('Login timeout: Sunucu yanıt vermedi. Lütfen internet bağlantınızı kontrol edin.');
      } else if (e is SocketException) {
        throw Exception('Bağlantı hatası: Sunucuya ulaşılamıyor. Lütfen internet bağlantınızı ve sunucu adresini kontrol edin.');
      }
      throw Exception('Login error: $e');
    }
  }

  // Token'ı kaydet
  Future<void> saveToken(String token) async {
    await _prefs.setString('token', token);
    _token = token;
  }

  // Token'ı sil
  Future<void> clearToken() async {
    await _prefs.remove('token');
    _token = null;
  }

  // Token'ı al
  String? getToken() {
    return _token;
  }

  // HTTP istekleri için header'ları hazırla
  Map<String, String> _getHeaders() {
    print('Kullanılan token: \'$_token\'');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
    print('Kullanılan headerlar: $headers');
    return headers;
  }

  // Kullanıcı kaydı
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/authentication/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        await _prefs.setString('username', email);
        // userId kaydet
        if (data['userId'] != null) {
          await _prefs.setString('userId', data['userId'].toString());
        } else {
          // Eğer backend dönmüyorsa, mevcut userId fonksiyonunu kullan
          await getUserId();
        }
        return data;
      } else {
        throw Exception('Registration failed: \n${response.body}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Yemek listesini getir
  Future<List<dynamic>> getMeals() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meals'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load meals: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading meals: $e');
    }
  }

  // Yeni yemek ekle
  Future<Map<String, dynamic>> addMeal(Map<String, dynamic> mealData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/meals'),
        headers: _getHeaders(),
        body: jsonEncode(mealData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add meal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding meal: $e');
    }
  }

  // Yemek güncelle
  Future<Map<String, dynamic>> updateMeal(int mealId, Map<String, dynamic> mealData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/meals/$mealId'),
        headers: _getHeaders(),
        body: jsonEncode(mealData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update meal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating meal: $e');
    }
  }

  // Yemek sil
  Future<void> deleteMeal(int mealId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/meals/$mealId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete meal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting meal: $e');
    }
  }

  // Kullanıcıya özel userId'yi sakla/oku
  Future<String> getUserId() async {
    String? userId = _prefs.getString('userId');
    if (userId == null) {
      // Sadece '1' olarak ata (veya backend'deki gerçek userId)
      userId = '1';
      await _prefs.setString('userId', userId);
    }
    print('KULLANILAN USER ID: $userId');
    return userId;
  }

  // Diyet planı oluştur
  Future<String> createDietPlan({
    required String message,
    required int age,
    required int height,
    required int weight,
    required String gender,
    required String goal,
    required String name,
    required String dietType,
  }) async {
    try {
      final userId = await getUserId();
      final response = await http.post(
        Uri.parse('$_difyUrl/chat-messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_difyApiKey',
        },
        body: jsonEncode({
          'inputs': {
            'yas': age.toString(),
            'boy': height.toString(),
            'kilo': weight.toString(),
            'cinsiyet': gender,
            'hedef': goal,
            'isim': name,
            'diyet_tipi': dietType,
          },
          'query': message,
          'response_mode': 'blocking',
          'user': userId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'Yanıt alınamadı';
      } else {
        throw Exception('Failed to create diet plan: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating diet plan: $e');
    }
  }

  // Chatbot mesajı gönderme
  Future<String> sendChatbotMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot/ask'),
        headers: _getHeaders(),
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'Yanıt alınamadı';
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['error'] ?? 'Chatbot hatası: ${response.body}');
        } catch (e) {
          throw Exception('Chatbot hatası: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Chatbot iletişim hatası: $e');
    }
  }

  // Chatbot geçmişini getirme
  Future<List<dynamic>> getChatbotHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_difyUrl/chat/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _difyApiKey,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to get chat history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting chat history: $e');
    }
  }

  // Chatbot geçmişini temizleme
  Future<void> clearChatbotHistory() async {
    try {
      final response = await http.delete(
        Uri.parse('$_difyUrl/chat/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _difyApiKey,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to clear chat history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error clearing chat history: $e');
    }
  }

  // Dify ile conversation_id yönetimi
  Future<String?> getConversationId() async {
    return _prefs.getString('dify_conversation_id');
  }

  Future<void> setConversationId(String conversationId) async {
    await _prefs.setString('dify_conversation_id', conversationId);
  }

  Future<void> clearConversationId() async {
    await _prefs.remove('dify_conversation_id');
  }

  // Parçalı Dify yanıtını mevcut planla birleştirip backend'e kaydeder
  Future<void> updateDietPlanWithPartialResponse(int userId, Map<String, dynamic> partialResponse) async {
    // 1. Mevcut planı backend'den çek
    final currentPlanString = await getDietPlanFromServer(userId);
    Map<String, dynamic> currentPlan;
    if (currentPlanString != null && currentPlanString.isNotEmpty) {
      try {
        final decoded = jsonDecode(currentPlanString);
        if (decoded is Map && decoded.containsKey('plan')) {
          currentPlan = jsonDecode(decoded['plan']);
        } else {
          currentPlan = decoded;
        }
      } catch (e) {
        print('Mevcut plan parse hatası: $e');
        currentPlan = {'profil': {}, 'diyet_listesi': {}};
      }
    } else {
      // Hiç plan yoksa, yeni başlat
      currentPlan = {'profil': {}, 'diyet_listesi': {}};
    }

    // 2. Parçalı yanıtı mevcut plana uygula
    if (partialResponse.containsKey('diyet_listesi')) {
      partialResponse['diyet_listesi'].forEach((key, value) {
        currentPlan['diyet_listesi'][key] = value;
      });
    }
    if (partialResponse.containsKey('profil')) {
      currentPlan['profil'] = partialResponse['profil'];
    }

    print('Birleştirilmiş ve kaydedilecek plan: ${jsonEncode(currentPlan)}');

    // 3. Güncellenmiş planı backend'e kaydet
    await saveDietPlanToServer(userId, jsonEncode(currentPlan));
  }

  // Diyet planını backend'den sil
  Future<void> deleteDietPlanFromServer(int userId) async {
    final response = await http.delete(
      Uri.parse('http://172.28.240.1:5001/api/dietplan/$userId'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Diyet planı silinemedi: ${response.body}');
    }
  }

  // Dify API'ye doğrudan mesaj gönderme (conversation_id ile)
  Future<String> sendDirectDifyMessage(String message, {Map<String, dynamic>? inputs}) async {
    try {
      final userId = await getUserId();
      print('DIFY API - User ID: $userId');
      print('DIFY API - Message: $message');
      print('DIFY API - Inputs: $inputs');

      // Eğer mesaj silme komutuysa, doğrudan sil
      final lowerMsg = message.toLowerCase();
      if (lowerMsg.contains('planımı sil') || lowerMsg.contains('diyet planını sil') || lowerMsg.contains('planı sil')) {
        await deleteDietPlanFromServer(int.parse(userId));
        return 'Diyet planınız başarıyla silindi.';
      }

      final conversationId = await getConversationId();
      print('DIFY API - Conversation ID: $conversationId');

      final body = <String, dynamic>{
        'query': message,
        'response_mode': 'blocking',
        'user': userId,
        'inputs': inputs ?? {},
        if (conversationId != null) 'conversation_id': conversationId,
      };

      print('DIFY API REQUEST BODY: ' + jsonEncode(body));
      
      final response = await http.post(
        Uri.parse('$_difyUrl/chat-messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_difyApiKey',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print('DIFY API RESPONSE STATUS: ${response.statusCode}');
      print('DIFY API RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // conversation_id'yi sakla
        if (data['conversation_id'] != null) {
          await setConversationId(data['conversation_id']);
        }

        // answer alanı bazen iç içe JSON olabilir, düzelt
        String answer = data['answer'] ?? 'Yanıt alınamadı';
        print('DIFY API - Raw Answer: $answer');

        // Kod bloğu işaretlerini temizle
        answer = answer.replaceAll('```json', '').replaceAll('```', '').trim();
        
        try {
          final inner = jsonDecode(answer);
          if (inner is Map && inner['answer'] != null) {
            answer = inner['answer'];
            // Diyet planını backend'e kaydet (tüm planı veya parçalı yanıtı birleştirerek)
            if (inner['data'] != null) {
              await updateDietPlanWithPartialResponse(int.parse(userId), inner['data']);
            }
          }
        } catch (e) {
          print('DIFY API - JSON parse error: $e');
          // JSON parse hatası durumunda orijinal yanıtı kullan
        }

        return answer;
      } else {
        print('DIFY API ERROR: ${response.statusCode} - ${response.body}');
        throw Exception('Dify API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DIFY API EXCEPTION: $e');
      throw Exception('Dify API iletişim hatası: $e');
    }
  }

  // Diyet planını backend'e kaydet
  Future<void> saveDietPlanToServer(int userId, String plan) async {
    print('Backend\'e kaydedilecek plan: $plan');
    // Plan'ı JSON string'e çevir
    final planJson = jsonEncode({
      'userId': userId,
      'plan': plan,
      'createdAt': DateTime.now().toIso8601String(),
    });
    print('POST body: $planJson');
    final response = await http.post(
      Uri.parse('http://172.28.240.1:5001/api/dietplan'),
      headers: _getHeaders(),
      body: planJson,
    );
    print('Backend response: \x1B[32m${response.statusCode} ${response.body}\x1B[0m');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Diyet planı kaydedilemedi: \n${response.body}');
    }
  }

  // Diyet planını backend'den getir
  Future<String?> getDietPlanFromServer(int userId) async {
    final response = await http.get(
      Uri.parse('http://172.28.240.1:5001/api/dietplan/$userId'),
      headers: _getHeaders(),
    );
    print('Backend response status: ${response.statusCode}');
    print('Backend response body: ${response.body}');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return data['plan']?.toString();
      } catch (e) {
        print('JSON parse error: $e');
        return null;
      }
    }
    return null;
  }

  Future<String> updateProfile({
    required String? userId,
    required String currentPassword,
    required String newEmail,
    String? newPassword,
  }) async {
    print('Profil güncelleme başladı...');
    print('Backend URL: $_baseUrl/authentication/update-profile');
    print('Headers: ${_getHeaders()}');
    print('userId: $userId');
    print('newEmail: $newEmail');
    print('newPassword: ${newPassword ?? "değiştirilmedi"}');
    
    final requestBody = {
      'userId': int.tryParse(userId ?? '') ?? 0,
      'currentPassword': currentPassword,
      'newEmail': newEmail,
      'newPassword': newPassword,
    };
    print('Request body: $requestBody');
    
    try {
      print('API isteği gönderiliyor...');
      final response = await http.post(
        Uri.parse('$_baseUrl/authentication/update-profile'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('Profil güncelleme başarılı!');
        // Başarılı güncelleme durumunda SharedPreferences'da email'i güncelle
        await _prefs.setString('username', newEmail);
        return 'Profiliniz başarıyla güncellendi!';
      } else {
        print('Profil güncelleme başarısız! Status: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Profil güncellenemedi: ${response.body}');
        } catch (e) {
          throw Exception('Profil güncellenemedi: ${response.body}');
        }
      }
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      if (e is TimeoutException) {
        throw Exception('Sunucu yanıt vermedi. Lütfen internet bağlantınızı kontrol edin.');
      }
      throw Exception('Profil güncellenirken bir hata oluştu: $e');
    }
  }

  // Kullanıcı profilini getir
  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/profile'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        print('Kullanıcı profili bulunamadı');
        return null;
      } else {
        throw Exception('Failed to load user profile: ${response.body}');
      }
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }
}