import 'package:flutter/material.dart';
import 'package:dailydiet/screens/home_screen.dart';

class FoodDiaryScreen extends StatefulWidget {
  @override
  _FoodDiaryScreenState createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  final _foodController = TextEditingController();
  final _caloriesController = TextEditingController();
  List<Map<String, String>> foodDiary = [];

  void _addFood() {
    String food = _foodController.text.trim();
    String calories = _caloriesController.text.trim();
    if (food.isNotEmpty && calories.isNotEmpty) {
      setState(() {
        foodDiary.add({'food': food, 'calories': calories});
      });
      _foodController.clear();
      _caloriesController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yemek Günlüğü'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _foodController,
                  decoration: InputDecoration(
                    labelText: 'Yemek Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _caloriesController,
                  decoration: InputDecoration(
                    labelText: 'Kalori (kcal)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addFood,
                  child: Text('Yemek Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: foodDiary.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(foodDiary[index]['food']!),
                    subtitle: Text('${foodDiary[index]['calories']} kcal'),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/'),
              child: Text('Ana Sayfaya Dön'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}