import 'package:flutter/material.dart';
import 'package:dailydiet/services/api_service.dart';
import 'package:dailydiet/screens/chatbot_screen.dart';
import 'package:dailydiet/screens/diet_plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String chatbotTip = 'Yükleniyor...';
  int waterGlasses = 0;
  final int dailyWaterGoal = 8;
  Map<String, dynamic>? cachedDietPlan;
  String? lastUpdateDate;
  final List<String> motivationalQuotes = [
    "Sağlıklı bir vücut, sağlıklı bir zihnin anahtarıdır.",
    "Küçük adımlar, büyük değişimlere yol açar.",
    "Bugün yapabileceğini yarına bırakma.",
    "Her gün yeni bir başlangıçtır.",
    "Sağlıklı yaşam bir maraton, sprint değil.",
    "Kendine inan, başaracaksın!",
    "Her gün bir fırsat, her an bir şans.",
    "Sağlıklı yaşam, mutlu yaşam.",
    "Vücudun sana teşekkür edecek.",
    "Bugünün çabası, yarının başarısı."
  ];

  @override
  void initState() {
    super.initState();
    _updateMotivationQuote();
    _loadDietPlan();
  }

  Future<void> _loadDietPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Son güncelleme tarihini kontrol et
    lastUpdateDate = prefs.getString('lastUpdateDate');
    
    if (lastUpdateDate != today) {
      // Yeni gün başlamış, yeni veri çek
      try {
        final response = await http.get(Uri.parse('YOUR_API_ENDPOINT'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await prefs.setString('dietPlan', json.encode(data));
          await prefs.setString('lastUpdateDate', today);
          setState(() {
            cachedDietPlan = data;
            lastUpdateDate = today;
          });
        }
      } catch (e) {
        print('Diyet planı yüklenirken hata: $e');
      }
    } else {
      // Bugünün verisi zaten var, cache'den oku
      final cachedData = prefs.getString('dietPlan');
      if (cachedData != null) {
        setState(() {
          cachedDietPlan = json.decode(cachedData);
        });
      }
    }
  }

  void _updateMotivationQuote() {
    // Rastgele bir motivasyon sözü seç
    final random = DateTime.now().millisecondsSinceEpoch;
    final quoteIndex = random % motivationalQuotes.length;
    
    setState(() {
      chatbotTip = motivationalQuotes[quoteIndex];
    });
  }

  Widget _buildQuickStatsCard(double screenWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hızlı İstatistikler',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: 'Kalori',
                  value: '1200',
                  target: '1800',
                  unit: 'kcal',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.water_drop,
                  label: 'Su',
                  value: waterGlasses.toString(),
                  target: dailyWaterGoal.toString(),
                  unit: 'bardak',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.directions_walk,
                  label: 'Adım',
                  value: '3500',
                  target: '10000',
                  unit: 'adım',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String target,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          '$value / $target',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterTrackerCard(double screenWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Su Takibi',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  '$waterGlasses / $dailyWaterGoal bardak',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: waterGlasses / dailyWaterGoal,
              backgroundColor: Colors.blue.shade100,
              color: Colors.blue,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (waterGlasses > 0) {
                      setState(() {
                        waterGlasses--;
                      });
                    }
                  },
                  icon: Icon(Icons.remove),
                  label: Text('Çıkar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade900,
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (waterGlasses < dailyWaterGoal) {
                      setState(() {
                        waterGlasses++;
                      });
                    }
                  },
                  icon: Icon(Icons.add),
                  label: Text('Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DAILYDIET',
          style: TextStyle(fontSize: 20 * textScaleFactor),
        ),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
              vertical: 16.0
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hızlı İstatistikler
                _buildQuickStatsCard(screenWidth),
                
                SizedBox(height: 20),

                // Su Takibi
                _buildWaterTrackerCard(screenWidth),

                SizedBox(height: 20),

                // Chatbot İpucu
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Günün Motivasyonu',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          chatbotTip,
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 16 : 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Diyet Planı Butonu
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 24 : 16,
                        vertical: screenWidth > 600 ? 12 : 8,
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DietPlanScreen())
                    ),
                    icon: Icon(Icons.restaurant_menu),
                    label: Text(
                      'Diyet Planını Görüntüle',
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 18 : 16
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Chatbot Butonu
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 24 : 16,
                        vertical: screenWidth > 600 ? 12 : 8,
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatbotScreen())
                    ),
                    icon: Icon(Icons.chat),
                    label: Text(
                      'Chatbot ile Konuş',
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 18 : 16
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}