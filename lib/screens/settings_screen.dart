import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../models/models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? Colors.black,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(),
        builder: (context, Box settingsBox, _) {
          final isDarkMode = settingsBox.get('isDarkMode', defaultValue: false);
          
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Appearance Section
              Text('Appearance', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: SwitchListTile(
                  title: Text('Dark Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: isDarkMode,
                  onChanged: (val) => settingsBox.put('isDarkMode', val),
                  activeColor: Colors.blue,
                ),
              ),

              const SizedBox(height: 30),
              // Currency Section
              Text('Global Currency', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('USD (\$)', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      value: 'USD',
                      groupValue: settingsBox.get('globalCurrency', defaultValue: 'USD'),
                      onChanged: (val) => settingsBox.put('globalCurrency', val),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Text('INR (₹)', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      value: 'INR',
                      groupValue: settingsBox.get('globalCurrency', defaultValue: 'USD'),
                      onChanged: (val) => settingsBox.put('globalCurrency', val),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'All amounts will be shown in your selected currency',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              // Security Section
              Text('Security', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.shield, color: Colors.green),
                  title: Text('Data Encrypted', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text('AES-256 Bank-Grade Security Active', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ),
              ),

              const SizedBox(height: 30),
              // Invoice Preferences Section
              Text('Invoice Preferences', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.monetization_on_outlined, color: Colors.blue),
                      title: Text('Default Hourly Rate', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      subtitle: Text('\$${settingsBox.get('defaultRate', defaultValue: 50.0).toString()}/hr', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.edit, size: 16),
                      onTap: () => _updateSetting(context, settingsBox, 'defaultRate', 'Default Hourly Rate', isNumber: true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.percent, color: Colors.orange),
                      title: Text('Default Tax Rate', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      subtitle: Text('${settingsBox.get('defaultTax', defaultValue: 0.0).toString()}%', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.edit, size: 16),
                      onTap: () => _updateSetting(context, settingsBox, 'defaultTax', 'Default Tax Rate (%)', isNumber: true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              // Data Management Section
              Text('Data Management', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                     ListTile(
                      leading: const Icon(Icons.copy),
                      title: Text('Backup Data (Copy)', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      subtitle: Text('Copy all data to clipboard', style: GoogleFonts.poppins(fontSize: 12)),
                      onTap: () => _copyData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.paste),
                      title: Text('Restore Data (Paste)', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      subtitle: Text('Paste JSON to restore', style: GoogleFonts.poppins(fontSize: 12)),
                      onTap: () => _pasteData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: Text('Clear All Data', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.red)),
                      onTap: () => _clearAllData(context),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              Center(
                child: Text('Version 1.5.0', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _updateSetting(BuildContext context, Box box, String key, String title, {bool isNumber = false}) async {
    final controller = TextEditingController(text: box.get(key)?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
             onPressed: () {
               if (isNumber) {
                 final val = double.tryParse(controller.text);
                 if (val != null) box.put(key, val);
               } else {
                 box.put(key, controller.text);
               }
               Navigator.pop(context);
             }, 
             child: const Text('Save')
          ),
        ],
      ),
    );
  }

  Future<void> _copyData(BuildContext context) async {
    final proposals = Hive.box<Proposal>('proposals').values.map((e) => {
      'id': e.id, 'clientName': e.clientName, 'projectTitle': e.projectTitle, 
      'description': e.description, 'estimatedBudget': e.estimatedBudget, 
      'dateSent': e.dateSent.toIso8601String(), 'status': e.status
    }).toList();
    
    final projects = Hive.box<Project>('projects').values.map((e) => {
      'id': e.id, 'name': e.name, 'clientName': e.clientName, 
      'budget': e.budget, 'status': e.status, 'deadline': e.deadline.toIso8601String()
    }).toList();

    final tasks = Hive.box<TaskItem>('tasks').values.map((e) => {
      'id': e.id, 'projectId': e.projectId, 'title': e.title, 'isCompleted': e.isCompleted,
       'totalSeconds': e.totalSeconds, 'isRunning': e.isRunning, 'lastStartTime': e.lastStartTime
    }).toList();

    final invoices = Hive.box<Invoice>('invoices').values.map((e) => {
      'id': e.id, 'clientName': e.clientName, 'amount': e.amount, 
      'date': e.date.toIso8601String(), 'status': e.status
    }).toList();
    
    final clients = Hive.box<Client>('clients').values.map((e) => {
      'id': e.id, 'name': e.name, 'company': e.company, 'email': e.email, 'phone': e.phone, 'notes': e.notes
    }).toList();

    final allData = {
      'proposals': proposals,
      'projects': projects,
      'tasks': tasks,
      'invoices': invoices,
      'clients': clients,
      'version': 1,
    };

    final jsonString = jsonEncode(allData);
    await Clipboard.setData(ClipboardData(text: jsonString));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data copied to clipboard! Save this text safely.')),
      );
    }
  }

  Future<void> _pasteData(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;

    try {
      final json = jsonDecode(data!.text!) as Map<String, dynamic>;
      // Basic validation
      if (!json.containsKey('version')) throw Exception('Invalid data format');

      final confirm = await showDialog<bool>(
        context: context, 
        builder: (context) => AlertDialog(
          title: const Text('Restore Data?'),
          content: const Text('This will OVERWRITE your current data. Are you sure?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore', style: TextStyle(color: Colors.red))),
          ],
        )
      );

      if (confirm == true) {
         // Clear Existing
         await Hive.box<Proposal>('proposals').clear();
         await Hive.box<Project>('projects').clear();
         await Hive.box<TaskItem>('tasks').clear();
         await Hive.box<Invoice>('invoices').clear();
         await Hive.box<Client>('clients').clear();

         // Restore Proposals
         for (var item in (json['proposals'] as List)) {
           final p = Proposal(
             id: item['id'], clientName: item['clientName'], projectTitle: item['projectTitle'], 
             description: item['description'], estimatedBudget: (item['estimatedBudget'] as num).toDouble(), 
             dateSent: DateTime.parse(item['dateSent']), status: item['status']
           );
           Hive.box<Proposal>('proposals').put(p.id, p);
         }
         
         // Restore Projects
         for (var item in (json['projects'] as List)) {
           final p = Project(
             id: item['id'], name: item['name'], clientName: item['clientName'], 
             budget: (item['budget'] as num).toDouble(), status: item['status'], 
             deadline: DateTime.parse(item['deadline'])
           );
           Hive.box<Project>('projects').put(p.id, p);
         }

         // Restore Tasks
         for (var item in (json['tasks'] as List)) {
           final t = TaskItem(
             id: item['id'], projectId: item['projectId'], title: item['title'], isCompleted: item['isCompleted'],
             totalSeconds: item['totalSeconds'] ?? 0, isRunning: item['isRunning'] ?? false, lastStartTime: item['lastStartTime']
           );
           Hive.box<TaskItem>('tasks').put(t.id, t);
         }

         // Restore Invoices
         for (var item in (json['invoices'] as List)) {
           final i = Invoice(
             id: item['id'], clientName: item['clientName'], amount: (item['amount'] as num).toDouble(),
             date: DateTime.parse(item['date']), status: item['status']
           );
           Hive.box<Invoice>('invoices').put(i.id, i);
         }
         
         // Restore Clients
         if (json.containsKey('clients')) {
            for (var item in (json['clients'] as List)) {
              final c = Client(
                id: item['id'], name: item['name'], company: item['company'], 
                email: item['email'], phone: item['phone'], notes: item['notes']
              );
              Hive.box<Client>('clients').put(c.id, c);
            }
         }

         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restored successfully!')));
         }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error restoring: $e')));
      }
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirm = await showDialog<bool>(
        context: context, 
        builder: (context) => AlertDialog(
          title: const Text('Clear All Data?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear All', style: TextStyle(color: Colors.red))),
          ],
        )
      );
      
    if (confirm == true) {
      await Hive.box<Proposal>('proposals').clear();
      await Hive.box<Project>('projects').clear();
      await Hive.box<TaskItem>('tasks').clear();
      await Hive.box<Invoice>('invoices').clear();
      await Hive.box<Client>('clients').clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared.')));
      }
    }
  }
}
