import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../repositories/repository_manager.dart';
import '../widgets/app_card.dart';
import '../services/haptic_service.dart';

class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark, immersive feel for review
      body: StreamBuilder<List<TaskItem>>(
        stream: repositoryManager.tasks.getAll(),
        initialData: repositoryManager.tasks.getAllSync(),
        builder: (context, taskSnapshot) {
          return StreamBuilder<List<Invoice>>(
            stream: repositoryManager.invoices.getAll(),
            initialData: repositoryManager.invoices.getAllSync(),
            builder: (context, invoiceSnapshot) {
              if (!taskSnapshot.hasData || !invoiceSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tasks = taskSnapshot.data!;
              final invoices = invoiceSnapshot.data!;
              
              // Stats for this week
              final last7Days = DateTime.now().subtract(const Duration(days: 7));
              final weeklyTasks = tasks.where((t) => t.isCompleted).length; // Simplified
              final weeklyInvoiced = invoices.where((i) => i.date.isAfter(last7Days)).fold(0.0, (sum, i) => sum + i.amount);
              final weeklyPaid = invoices.where((i) => i.status == 'Paid' && i.date.isAfter(last7Days)).fold(0.0, (sum, i) => sum + i.amount);

              final slides = [
                _buildIntroSlide(),
                _buildStatsSlide('Impact Created', '$weeklyTasks Tasks Done', 'Every task is a step towards your vision.', Icons.check_circle_outline, Colors.green),
                _buildStatsSlide('Revenue Flow', '\$${weeklyInvoiced.toInt()} Invoiced', '\$${weeklyPaid.toInt()} collected this week.', Icons.payments_outlined, Colors.blue),
                _buildOutroSlide(),
              ];

              return Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: slides,
                  ),
                  // Progress indicators (bars)
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: List.generate(
                        slides.length,
                        (index) => Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: index <= _currentPage ? Colors.white : Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 50,
                    right: 10,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIntroSlide() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_outlined, color: Colors.amber, size: 80),
          const SizedBox(height: 32),
          Text(
            'Your Weekly Review',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Take a moment to reflect on your progress and energy.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 48),
          Text(
            'Swipe to begin',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSlide(String title, String stat, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 64),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            stat,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            subtext,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOutroSlide() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_outline, color: Colors.redAccent, size: 80),
          const SizedBox(height: 32),
          Text(
            'Well Done!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'You are building something beautiful. Rest well.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 64),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'CLOSE REVIEW',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
