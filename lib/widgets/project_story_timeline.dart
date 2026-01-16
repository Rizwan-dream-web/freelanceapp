import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TimelineNode {
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;
  final bool isCompleted;

  TimelineNode({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
    this.isCompleted = true,
  });
}

class ProjectStoryTimeline extends StatelessWidget {
  final List<TimelineNode> nodes;

  const ProjectStoryTimeline({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        final isLast = index == nodes.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line and Dot
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: node.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: node.color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(node.icon, size: 16, color: node.color),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          node.color.withOpacity(0.5),
                          nodes[index + 1].color.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    node.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().format(node.date),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: node.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
