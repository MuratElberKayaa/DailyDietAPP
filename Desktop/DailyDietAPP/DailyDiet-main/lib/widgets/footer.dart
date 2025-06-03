import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 32,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('+90 555 123 45 67'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.email, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('destek@dailydiet.com'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Yardım Merkezi'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '© 2024 DailyDiet. Tüm hakları saklıdır.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
} 