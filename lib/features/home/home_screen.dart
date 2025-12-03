import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(39, 83, 75, 1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PhotoNotes',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/account');
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color.fromRGBO(255, 231, 157, 1),
                            child: Icon(
                              Icons.star,
                              color: Color.fromRGBO(39, 83, 75, 1),
                              size: 32,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Привіт! Петро',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text('👋', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/empty_notes.png', width: 220),
                    const SizedBox(height: 32),
                    const Text(
                      'Нотаток немає',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Створіть Вашу першу нотатку',
                      style: TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                    const SizedBox(height: 50),

                    TextButton(
                      onPressed: () {
                        FirebaseCrashlytics.instance.crash();
                      },
                      style: TextButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text(
                        'Згенерувати тестовий креш (Fatal)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Non-fatal помилку надіслано до Crashlytics!',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );

                        try {
                          throw Exception(
                            "Це тестова non-fatal помилка. Застосунок не впав.",
                          );
                        } catch (error, stackTrace) {
                          FirebaseCrashlytics.instance.recordError(
                            error,
                            stackTrace,
                            reason: 'A non-fatal test error',
                            fatal: false,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'Згенерувати non-fatal помилку',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: SizedBox(
          width: 70,
          height: 70,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/home_full');
            },
            backgroundColor: const Color.fromRGBO(251, 228, 127, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 0,
            child: const Icon(
              Icons.add,
              color: Color.fromRGBO(0, 86, 49, 1),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
