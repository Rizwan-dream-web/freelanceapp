import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class QuickNotesSheet extends StatelessWidget {
  const QuickNotesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.lightbulb, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Idea Box', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue, size: 28),
                    onPressed: () => _showNoteEditor(context),
                  )
                ],
              ),
            ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Note>('notes').listenable(),
              builder: (context, Box<Note> box, _) {
                if (box.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Empty scratchpad', style: GoogleFonts.poppins(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                final notes = box.values.toList().cast<Note>();
                // Sort by last updated
                notes.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(context, note, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
     ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note, bool isDark) {
    // Sticky note colors
    final colors = isDark 
      ? [Colors.grey[800]!, const Color(0xFF3E2723), const Color(0xFF1A237E), const Color(0xFF004D40)]
      : [const Color(0xFFFFF9C4), const Color(0xFFFFCCBC), const Color(0xFFE1BEE7), const Color(0xFFC8E6C9)]; // Yellow, Orange, Purple, Green (Light)
    
    final color = colors[note.colorIndex % colors.length];
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return GestureDetector(
      onTap: () => _showNoteEditor(context, note: note),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(2, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                note.content,
                style: GoogleFonts.kalam( // Handwritten style font if possible, else poppins
                  fontSize: 14,
                  color: textColor,
                  height: 1.4,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                   DateFormat.MMMd().format(note.lastUpdated),
                   style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.white30 : Colors.black38),
                ),
                GestureDetector(
                  onTap: () {
                    final box = Hive.box<Note>('notes');
                    box.delete(note.id);
                  },
                  child: Icon(Icons.delete_outline, size: 16, color: isDark ? Colors.white30 : Colors.black38),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showNoteEditor(BuildContext context, {Note? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(note: note),
    );
  }
}

class NoteEditor extends StatefulWidget {
  final Note? note;

  const NoteEditor({super.key, this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _controller;
  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note?.content ?? '');
    _colorIndex = widget.note?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      if (widget.note != null) {
         Hive.box<Note>('notes').delete(widget.note!.id);
      }
      return;
    }

    final box = Hive.box<Note>('notes');
    final id = widget.note?.id ?? const Uuid().v4();
    final note = Note(
      id: id,
      content: text,
      lastUpdated: DateTime.now(),
      colorIndex: _colorIndex,
    );
    box.put(id, note);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Suggest colors
    final colors = isDark 
      ? [Colors.grey[800]!, const Color(0xFF3E2723), const Color(0xFF1A237E), const Color(0xFF004D40)]
      : [const Color(0xFFFFF9C4), const Color(0xFFFFCCBC), const Color(0xFFE1BEE7), const Color(0xFFC8E6C9)]; 

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Edit Note', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Row(
                children: [
                   for (int i = 0; i < colors.length; i++)
                     GestureDetector(
                       onTap: () => setState(() => _colorIndex = i),
                       child: Container(
                         margin: const EdgeInsets.only(left: 8),
                         width: 24, height: 24,
                         decoration: BoxDecoration(
                           color: colors[i],
                           shape: BoxShape.circle,
                           border: _colorIndex == i ? Border.all(color: Colors.blue, width: 2) : null,
                         ),
                       ),
                     ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 6,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Write something...',
              border: InputBorder.none,
            ),
            style: GoogleFonts.kalam(fontSize: 18, height: 1.5), // Use handwriting style
          ),
          Divider(color: Colors.grey[200]),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                   _save();
                   Navigator.pop(context);
                },
                child: Text('Done', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
