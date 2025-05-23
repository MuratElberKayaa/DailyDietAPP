import 'package:flutter/material.dart';
import 'package:dailydiet/screens/chatbot_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({Key? key}) : super(key: key);

  @override
  _DietPlanScreenState createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  Map<String, dynamic>? dietPlans;
  bool isLoading = true;
  String? errorMessage;
  Map<int, Set<int>> checkedFoods = {};

  @override
  void initState() {
    super.initState();
    _loadDietPlan();
  }

  Future<void> _loadDietPlan() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastUpdateDate = prefs.getString('dietPlanLastUpdate');
    
    // Eğer bugünün verisi varsa, cache'den oku
    if (lastUpdateDate == today) {
      final cachedData = prefs.getString('dietPlanData');
      if (cachedData != null) {
        setState(() {
          dietPlans = json.decode(cachedData);
          isLoading = false;
        });
        return;
      }
    }

    // Cache'de veri yoksa veya güncel değilse, API'den çek
    await fetchDietPlan();
  }

  Future<void> fetchDietPlan() async {
    const apiKey = "app-sSUEH7mJmlsecDJEdbPcbckt";
    const workflowId = "62ce4a0d-ab01-4df0-8d9f-d79df7521a4b";
    const baseUrl = "https://api.dify.ai/v1";

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    final requestBody = {
      "workflow_id": workflowId,
      "inputs": {
        "yas": "25",
        "cinsiyet": "erkek",
        "boy": "180",
        "kilogram": "85",
        "hedef": "kilo vermek",
        "hareket_seviyesi": "orta"
      },
      "response_mode": "streaming",
      "user": "abc-123"
    };

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/workflows/run"),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 60));

      if (response.statusCode == 200) {
        final stream = response.body.split('\n');
        Map<String, dynamic>? dietJson;

        for (var line in stream) {
          if (line.startsWith("data:")) {
            try {
              final data = jsonDecode(line.replaceFirst("data:", "").trim());
              if (data["event"] == "workflow_finished") {
                dietJson = jsonDecode(data["data"]["outputs"]["diet_json"]);
                break;
              }
            } catch (e) {
              print("JSON ayrıştırma hatası: $e");
            }
          }
        }

        if (dietJson != null) {
          // Veriyi SharedPreferences'a kaydet
          final prefs = await SharedPreferences.getInstance();
          final today = DateTime.now().toIso8601String().split('T')[0];
          await prefs.setString('dietPlanData', json.encode(dietJson));
          await prefs.setString('dietPlanLastUpdate', today);

          setState(() {
            dietPlans = dietJson;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "Diyet planı alınamadı";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Hata oluştu: ${response.statusCode} ${response.body}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Bağlantı hatası: $e";
        isLoading = false;
      });
    }
  }

  Widget _buildResponsiveCard({
    required String title,
    required Widget child,
    double? height,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          child: Container(
            width: constraints.maxWidth,
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: constraints.maxWidth > 600 ? 18 : 16,
                      fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 10),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value),
      ],
    );
  }

  Widget _buildNutrientChip({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black54),
          SizedBox(width: 4),
          Text(
            '$value $unit',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(dynamic meal, double screenWidth) {
    int mealIndex = dietPlans!["ogunler"].indexOf(meal);
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  meal['ogunAdi'],
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: meal['yemekler'].length,
            itemBuilder: (context, foodIndex) {
              final food = meal['yemekler'][foodIndex];
              final isChecked = checkedFoods[mealIndex]?.contains(foodIndex) ?? false;
              
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          checkedFoods.putIfAbsent(mealIndex, () => <int>{});
                          if (val == true) {
                            checkedFoods[mealIndex]!.add(foodIndex);
                          } else {
                            checkedFoods[mealIndex]!.remove(foodIndex);
                          }
                        });
                      },
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  title: Text(
                    food['yemek'],
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 16 : 14,
                      fontWeight: FontWeight.w500,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? Colors.grey : Colors.black87,
                    ),
                  ),
                  subtitle: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildNutrientChip(
                        icon: Icons.local_fire_department,
                        value: '${food['kalori']}',
                        unit: 'kcal',
                        color: Colors.orange.shade100,
                      ),
                      _buildNutrientChip(
                        icon: Icons.grain,
                        value: '${food['karbonhidrat']}',
                        unit: 'g karb',
                        color: Colors.brown.shade100,
                      ),
                      _buildNutrientChip(
                        icon: Icons.fitness_center,
                        value: '${food['protein']}',
                        unit: 'g pro',
                        color: Colors.red.shade100,
                      ),
                      _buildNutrientChip(
                        icon: Icons.opacity,
                        value: '${food['yag']}',
                        unit: 'g yağ',
                        color: Colors.yellow.shade100,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate total target calories from diet plan
    int totalTargetCalories = 0;
    if (dietPlans != null && dietPlans!['ogunler'] != null) {
      for (var meal in dietPlans!['ogunler']) {
        for (var food in meal['yemekler']) {
          String calStr = food['kalori'].toString().replaceAll(RegExp(r'[^0-9]'), '');
          totalTargetCalories += int.tryParse(calStr) ?? 0;
        }
      }
    }

    // Calculate consumed calories based on checked checkboxes
    int consumedCalories = 0;
    checkedFoods.forEach((mealIndex, foodIndices) {
      if (dietPlans != null && dietPlans!['ogunler'] != null && mealIndex < dietPlans!['ogunler'].length) {
        var meal = dietPlans!['ogunler'][mealIndex];
        for (var foodIndex in foodIndices) {
          if (foodIndex < meal['yemekler'].length) {
            String calStr = meal['yemekler'][foodIndex]['kalori'].toString().replaceAll(RegExp(r'[^0-9]'), '');
            consumedCalories += int.tryParse(calStr) ?? 0;
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Diyet Planı'),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
            vertical: 16.0
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Günlük Özet
                _buildResponsiveCard(
                  title: 'Günlük Özet',
                  child: Column(
                    children: [
                      _buildInfoRow('Hedef Kalori:', '${totalTargetCalories.toString()} kcal'),
                      SizedBox(height: 10),
                      _buildInfoRow('Tüketilen:', '${consumedCalories.toString()} kcal'),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: totalTargetCalories > 0 ? consumedCalories / totalTargetCalories : 0,
                        backgroundColor: Colors.grey[200],
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Diyet Planı
                Text(
                  'Bugünün Diyet Planı',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 22 : 18,
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 10),

                if (isLoading)
                  Center(child: CircularProgressIndicator())
                else if (errorMessage != null)
                  Text(
                    'Hata: $errorMessage',
                    style: TextStyle(color: Colors.red)
                  )
                else if (dietPlans != null && dietPlans!['ogunler'] != null)
                  ...dietPlans!['ogunler'].map<Widget>((meal) {
                    return _buildMealSection(meal, screenWidth);
                  }).toList()
                else
                  Text('Diyet planı bulunamadı.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}