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
  int _selectedIndex = 0;
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Günlük İstatistikler',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
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
      ),
    );
  }

  Widget _buildWaterTrackerCard(double screenWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Su Takibi',
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$waterGlasses / $dailyWaterGoal bardak',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: waterGlasses / dailyWaterGoal,
                backgroundColor: Colors.blue.shade100,
                color: Colors.blue,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 20),
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
                  icon: const Icon(Icons.remove),
                  label: const Text('Çıkar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (waterGlasses < dailyWaterGoal) {
                      setState(() {
                        waterGlasses++;
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard(double screenWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Günün Motivasyonu',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              chatbotTip,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            'Sağlıklı bir gün geçir!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {
                              // Bildirimler sayfasına git
                            },
                            color: Colors.green.shade700,
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_outline),
                            onPressed: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildQuickStatsCard(screenWidth),
                _buildWaterTrackerCard(screenWidth),
                _buildMotivationCard(screenWidth),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.chat),
        label: const Text('Diyet Asistanı'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              // Ana sayfada kal
              break;
            case 1:
              Navigator.pushNamed(context, '/diet-plan');
              break;
            case 2:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Diyet Planı',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}