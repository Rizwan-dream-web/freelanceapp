import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart'; // To access MainContainer

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Master Your\nWorkflow.',
      'subtitle': 'The ultimate command center for your freelance business. Offline-first, agency-grade.',
      'icon': 'work'
    },
    {
      'title': 'Proposals That\nWin Work.',
      'subtitle': 'Send professional, high-converting proposals that make you stand out from the crowd.',
      'icon': 'description'
    },
    {
      'title': 'Invoicing That\nFeels Like Money.',
      'subtitle': 'Generate agency-grade invoices and celebrate every payment with style.',
      'icon': 'payments'
    },
  ];

  void _finishOnboarding() {
    Hive.box('settings').put('hasSeenOnboarding', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainContainer()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _buildPage(
                _pages[index]['title']!,
                _pages[index]['subtitle']!,
                _pages[index]['icon']!,
              );
            },
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Button
                 ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white
                  ),
                  child: Icon(_currentPage == _pages.length - 1 ? Icons.check : Icons.arrow_forward),
                ),
              ],
            ),
          ),

          // Skip Button
          Positioned(
            top: 60,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(String title, String subtitle, String iconKey) {
    IconData icon;
    switch (iconKey) {
      case 'work': icon = Icons.work_outline; break;
      case 'description': icon = Icons.description_outlined; break;
      case 'payments': icon = Icons.payments_outlined; break;
      default: icon = Icons.star;
    }

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 60, color: Colors.blue),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
