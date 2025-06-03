import 'package:flutter/material.dart';
import 'package:dailydiet/screens/chatbot_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dailydiet/services/api_service.dart';
import 'package:flutter/widgets.dart';
import '../../main.dart'; // routeObserver'ın tanımlı olduğu dosya yolunu kendi projenize göre ayarlayın
import 'package:dailydiet/models/diet_plan.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({Key? key}) : super(key: key);

  @override
  _DietPlanScreenState createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> with RouteAware {
  DietPlan? dietPlan;
  bool isLoading = true;
  String? errorMessage;
  Map<int, Set<int>> checkedFoods = {};
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _ensureUserId().then((_) => _initApiService());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Bu ekrana geri dönüldüğünde planı güncelle
    _loadDietPlan();
  }

  Future<void> _ensureUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null || userId.isEmpty) {
      // Geçici olarak elle userId ata (ör: 1)
      await prefs.setString('userId', '1');
      userId = '1';
    }
    print('KULLANILAN USER ID: ' + userId);
  }

  Future<void> _initApiService() async {
    _apiService = await ApiService.getInstance();
    await _loadDietPlan();
  }

  // Backend'den gelen planı modele uygun formata çevir
  Map<String, dynamic> convertBackendPlanToModel(Map<String, dynamic> backendPlan) {
    List<Map<String, dynamic>> ogunler = [];
    if (backendPlan['kahvalti'] != null) {
      ogunler.add({'ogunAdi': 'Kahvaltı', 'yemekler': backendPlan['kahvalti']});
    }
    if (backendPlan['ogle'] != null) {
      ogunler.add({'ogunAdi': 'Öğle', 'yemekler': backendPlan['ogle']});
    }
    if (backendPlan['aksam'] != null) {
      ogunler.add({'ogunAdi': 'Akşam', 'yemekler': backendPlan['aksam']});
    }
    if (backendPlan['ara_ogun'] != null) {
      ogunler.add({'ogunAdi': 'Ara Öğün', 'yemekler': backendPlan['ara_ogun']});
    }
    if (backendPlan['su'] != null) {
      ogunler.add({'ogunAdi': 'Su', 'yemekler': backendPlan['su']});
    }
    return {'ogunler': ogunler};
  }

  Future<void> _loadDietPlan() async {
    setState(() {
      isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userId');
      final userId = int.tryParse(userIdString ?? '') ?? 0;
      print('Diyet planı yükleniyor...');
      final rawData = await _apiService.getDietPlanFromServer(userId);
      print('Backend\'den gelen ham veri: $rawData');
      if (rawData != null && rawData.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawData);
          print('Backend\'den decode edilen veri: $decoded');
          Map<String, dynamic> planJson;
          if (decoded is Map && decoded.containsKey('plan')) {
            planJson = jsonDecode(decoded['plan']);
          } else {
            planJson = decoded;
          }
          final modelPlan = planJson['ogunler'] != null
              ? planJson
              : convertBackendPlanToModel(planJson['diyet_listesi'] ?? planJson);
          final dietPlan = DietPlan.fromJson(modelPlan);
          setState(() {
            this.dietPlan = dietPlan;
            isLoading = false;
          });
        } catch (e) {
          print('Model parse hatası: $e');
          setState(() {
            dietPlan = null;
            isLoading = false;
            errorMessage = 'Diyet planı verisi işlenemedi. Lütfen tekrar oluşturun.';
          });
        }
      } else {
        print('Plan bulunamadı');
        setState(() {
          dietPlan = null;
          isLoading = false;
          errorMessage = 'Hata: Henüz bir diyet planı oluşturmadınız. Chatbot ile bir plan oluşturun.';
        });
      }
    } catch (e) {
      print('Diyet planı yükleme hatası: $e');
      setState(() {
        dietPlan = null;
        isLoading = false;
        errorMessage = 'Diyet planı yüklenirken hata oluştu.';
      });
    }
  }

  Widget _buildNutrientChip({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$value $unit',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(Meal meal, double screenWidth) {
    int mealIndex = dietPlan!.meals.indexOf(meal);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.restaurant_menu, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  meal.name,
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meal.foods.length,
            itemBuilder: (context, foodIndex) {
              final food = meal.foods[foodIndex];
              final isChecked = checkedFoods[mealIndex]?.contains(foodIndex) ?? false;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isChecked ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? Colors.green.shade200 : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Checkbox(
                    value: isChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        checkedFoods[mealIndex] ??= {};
                        if (value == true) {
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
                  title: Text(
                    food.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isChecked ? Colors.green.shade700 : Colors.grey.shade800,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (food.calories != null)
                            _buildNutrientChip(
                              icon: Icons.local_fire_department,
                              value: food.calories.toString(),
                              unit: 'kcal',
                              color: Colors.orange,
                            ),
                          if (food.protein != null)
                            _buildNutrientChip(
                              icon: Icons.fitness_center,
                              value: food.protein.toString(),
                              unit: 'g protein',
                              color: Colors.blue,
                            ),
                          if (food.carbs != null)
                            _buildNutrientChip(
                              icon: Icons.grain,
                              value: food.carbs.toString(),
                              unit: 'g karbonhidrat',
                              color: Colors.purple,
                            ),
                          if (food.fat != null)
                            _buildNutrientChip(
                              icon: Icons.water_drop,
                              value: food.fat.toString(),
                              unit: 'g yağ',
                              color: Colors.red,
                            ),
                        ],
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

    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              // Üst Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                          color: Colors.green.shade700,
                        ),
                        Text(
                          'Diyet Planı',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadDietPlan,
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
              ),
              // Ana İçerik
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : dietPlan == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage ?? 'Henüz bir diyet planı oluşturmadınız.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ChatbotScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat),
                                    label: const Text('Chatbot ile Plan Oluştur'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: dietPlan!.meals.map((meal) => _buildMealSection(meal, screenWidth)).toList(),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}