import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final SharedPreferences _prefs;
  final String _baseUrl = 'http://127.0.0.1:5001/api';
  final String _difyUrl = 'https://api.dify.ai/v1';
  final String _difyApiKey = 'app-c0sDecUl7VaGJxQP2ifV5s6S';
  String? _token;

  ApiService(this._prefs) {
    _token = _prefs.getString('token');
  }

  // Login işlemi
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Authentication/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
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
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Kullanıcı kaydı
  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        return data;
      } else {
        throw Exception('Registration failed: ${response.body}');
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
      final response = await http.post(
        Uri.parse('$_difyUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _difyApiKey,
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
          'user': 'user',
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
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5001/api/chatbot/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['answer'] ?? 'Yanıt alınamadı';
    } else {
      // Hata mesajını göster
      try {
        final data = jsonDecode(response.body);
        return data['error'] ?? 'Chatbot hatası: \\${response.body}';
      } catch (e) {
        return 'Chatbot hatası: \\${response.body}';
      }
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
}