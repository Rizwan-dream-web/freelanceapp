import 'package:hive/hive.dart';

// --- Note Model ---
class Note extends HiveObject {
  String id;
  String content;
  DateTime lastUpdated;
  int colorIndex; // For sticky note colors
  String? uid;

  Note({
    required this.id,
    required this.content,
    required this.lastUpdated,
    this.colorIndex = 0,
    this.uid,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'colorIndex': colorIndex,
      'uid': uid,
    };
  }

  static Note fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      content: map['content'],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      colorIndex: map['colorIndex'],
      uid: map['uid'],
    );
  }
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 5;

  @override
  Note read(BinaryReader reader) {
    return Note(
      id: reader.readString(),
      content: reader.readString(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      colorIndex: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.content);
    writer.writeInt(obj.lastUpdated.millisecondsSinceEpoch);
    writer.writeInt(obj.colorIndex);
  }
}

// --- Client Model ---
class Client extends HiveObject {
  String id;
  String name;
  String company;
  String email;
  String phone;
  String notes;
  String? uid;

  Client({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.notes,
    this.uid,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'email': email,
      'phone': phone,
      'notes': notes,
      'uid': uid,
    };
  }

  static Client fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      company: map['company'],
      email: map['email'],
      phone: map['phone'],
      notes: map['notes'],
      uid: map['uid'],
    );
  }
}

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 4;

  @override
  Client read(BinaryReader reader) {
    return Client(
      id: reader.readString(),
      name: reader.readString(),
      company: reader.readString(),
      email: reader.readString(),
      phone: reader.readString(),
      notes: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.company);
    writer.writeString(obj.email);
    writer.writeString(obj.phone);
    writer.writeString(obj.notes);
  }
}

// --- Proposal Model ---
class Proposal extends HiveObject {
  String id;
  String clientName;
  String projectTitle;
  String description;
  double estimatedBudget;
  DateTime dateSent;
  String status; // 'Pending', 'Accepted', 'Rejected'
  String timeline; // New for v2

  String style; // 'Creative', 'Corporate', 'Minimal'
  String? uid;

  Proposal({
    required this.id,
    required this.clientName,
    required this.projectTitle,
    required this.description,
    required this.estimatedBudget,
    required this.dateSent,
    this.status = 'Pending',
    this.timeline = '',
    this.style = 'Corporate',
    this.uid,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'projectTitle': projectTitle,
      'description': description,
      'estimatedBudget': estimatedBudget,
      'dateSent': dateSent.millisecondsSinceEpoch,
      'status': status,
      'timeline': timeline,
      'style': style,
      'uid': uid,
    };
  }

  static Proposal fromMap(Map<String, dynamic> map) {
    return Proposal(
      id: map['id'],
      clientName: map['clientName'],
      projectTitle: map['projectTitle'],
      description: map['description'],
      estimatedBudget: (map['estimatedBudget'] as num).toDouble(),
      dateSent: DateTime.fromMillisecondsSinceEpoch(map['dateSent']),
      status: map['status'],
      timeline: map['timeline'] ?? '',
      style: map['style'] ?? 'Corporate',
      uid: map['uid'],
    );
  }
}

class ProposalAdapter extends TypeAdapter<Proposal> {
  @override
  final int typeId = 0;

  @override
  Proposal read(BinaryReader reader) {
    String id = reader.readString();
    String clientName = reader.readString();
    String projectTitle = reader.readString();
    String description = reader.readString();
    double estimatedBudget = reader.readDouble();
    DateTime dateSent = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    String status = reader.readString();
    
    // Migration
    String timeline = '';
    String style = 'Corporate';
    if (reader.availableBytes > 0) {
      timeline = reader.readString();
    }
    if (reader.availableBytes > 0) {
      style = reader.readString();
    }

    return Proposal(
      id: id,
      clientName: clientName,
      projectTitle: projectTitle,
      description: description,
      estimatedBudget: estimatedBudget,
      dateSent: dateSent,
      status: status,
      timeline: timeline,
      style: style,
    );
  }

  @override
  void write(BinaryWriter writer, Proposal obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.clientName);
    writer.writeString(obj.projectTitle);
    writer.writeString(obj.description);
    writer.writeDouble(obj.estimatedBudget);
    writer.writeInt(obj.dateSent.millisecondsSinceEpoch);
    writer.writeString(obj.status);
    writer.writeString(obj.timeline);
    writer.writeString(obj.style);
  }
}

// --- Project Model ---
class Project extends HiveObject {
  String id;
  String name;
  String clientName;
  double budget;
  String status; // 'Not Started', 'In Progress', 'On Hold', 'Completed'
  DateTime deadline;
  int estimatedHours; // New for v2
  String? clientId; // Link to Client model
  String currency; // 'USD' or 'INR'
  String? uid;

  Project({
    required this.id,
    required this.name,
    required this.clientName,
    required this.budget,
    this.status = 'Not Started',
    required this.deadline,
    this.estimatedHours = 0,
    this.clientId,
    this.currency = 'USD',
    this.uid,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientName': clientName,
      'budget': budget,
      'status': status,
      'deadline': deadline.millisecondsSinceEpoch,
      'estimatedHours': estimatedHours,
      'clientId': clientId,
      'currency': currency,
      'uid': uid,
    };
  }

  static Project fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      clientName: map['clientName'],
      budget: (map['budget'] as num).toDouble(),
      status: map['status'],
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline']),
      estimatedHours: map['estimatedHours'] ?? 0,
      clientId: map['clientId'],
      currency: map['currency'] ?? 'USD',
      uid: map['uid'],
    );
  }
}

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 1;

  @override
  Project read(BinaryReader reader) {
    String id = reader.readString();
    String name = reader.readString();
    String clientName = reader.readString();
    double budget = reader.readDouble();
    String status = reader.readString();
    DateTime deadline = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    
    // Migration for estimatedHours
    int estimatedHours = 0;
    if (reader.availableBytes > 0) {
      estimatedHours = reader.readInt();
    }
    // Migration for clientId and currency
    String? clientId;
    String currency = 'USD';
    if (reader.availableBytes > 0) {
      bool hasClientId = reader.readBool();
      if (hasClientId) clientId = reader.readString();
      if (reader.availableBytes > 0) currency = reader.readString();
    }

    return Project(
      id: id,
      name: name,
      clientName: clientName,
      budget: budget,
      status: status,
      deadline: deadline,
      estimatedHours: estimatedHours,
      clientId: clientId,
      currency: currency,
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.clientName);
    writer.writeDouble(obj.budget);
    writer.writeString(obj.status);
    writer.writeInt(obj.deadline.millisecondsSinceEpoch);
    writer.writeInt(obj.estimatedHours);
    // Write new fields
    writer.writeBool(obj.clientId != null);
    if (obj.clientId != null) writer.writeString(obj.clientId!);
    writer.writeString(obj.currency);
  }
}

// --- Task Model ---
class TaskItem extends HiveObject {
  String id;
  String projectId;
  String title;
  bool isCompleted;
  
  // Time Tracking Fields
  int totalSeconds;
  bool isRunning;
  int? lastStartTime; // Milliseconds since epoch
  Map<String, int> dailyTracked; // yyyy-MM-dd -> seconds
  String? uid;

  TaskItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.isCompleted = false,
    this.totalSeconds = 0,
    this.isRunning = false,
    this.lastStartTime,
    Map<String, int>? dailyTracked,
    this.uid,
  }) : dailyTracked = dailyTracked ?? {};
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'isCompleted': isCompleted,
      'totalSeconds': totalSeconds,
      'isRunning': isRunning,
      'lastStartTime': lastStartTime,
      'dailyTracked': dailyTracked,
      'uid': uid,
    };
  }

  static TaskItem fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'],
      projectId: map['projectId'],
      title: map['title'],
      isCompleted: map['isCompleted'],
      totalSeconds: map['totalSeconds'] ?? 0,
      isRunning: map['isRunning'] ?? false,
      lastStartTime: map['lastStartTime'],
      dailyTracked: Map<String, int>.from(map['dailyTracked'] ?? {}),
      uid: map['uid'],
    );
  }
}

class TaskAdapter extends TypeAdapter<TaskItem> {
  @override
  final int typeId = 2;

  @override
  TaskItem read(BinaryReader reader) {
    // Basic fields that always existed
    final id = reader.readString();
    final projectId = reader.readString();
    final title = reader.readString();
    final isCompleted = reader.readBool();
    
    // Potential new fields for migration
    int totalSeconds = 0;
    bool isRunning = false;
    int? lastStartTime;
    Map<String, int> dailyTracked = {};

    try {
      // Attempt to read new fields if they exist
      if (reader.availableBytes > 0) totalSeconds = reader.readInt();
      if (reader.availableBytes > 0) isRunning = reader.readBool();
      if (reader.availableBytes > 0) {
        final hasTime = reader.readBool();
        if (hasTime) {
          lastStartTime = reader.readInt();
        }
      }
      if (reader.availableBytes > 0) {
        dailyTracked = Map<String, int>.from(reader.readMap());
      }
    } catch (e) {
      // Ignore read errors for backward compatibility
    }

    return TaskItem(
      id: id,
      projectId: projectId,
      title: title,
      isCompleted: isCompleted,
      totalSeconds: totalSeconds,
      isRunning: isRunning,
      lastStartTime: lastStartTime,
      dailyTracked: dailyTracked,
    );
  }

  @override
  void write(BinaryWriter writer, TaskItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.projectId);
    writer.writeString(obj.title);
    writer.writeBool(obj.isCompleted);
    // New fields
    writer.writeInt(obj.totalSeconds);
    writer.writeBool(obj.isRunning);
    if (obj.lastStartTime != null) {
      writer.writeBool(true);
      writer.writeInt(obj.lastStartTime!);
    } else {
      writer.writeBool(false);
    }
    writer.writeMap(obj.dailyTracked);
  }
}

// --- Invoice Model ---
class Invoice extends HiveObject {
  String id;
  String clientName;
  double amount;
  DateTime date;
  String status; // 'Paid', 'Pending'
  String? projectId; // Linked project
  bool isExternal; // For invoices without a project
  String currency; // 'USD' or 'INR'
  bool isGstEnabled; // GST Support
  double gstPercentage;
  String description; // Invoice description/notes
  String? uid;

  Invoice({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.date,
    this.status = 'Pending',
    this.projectId,
    this.isExternal = false,
    this.currency = 'USD',
    this.isGstEnabled = false,
    this.gstPercentage = 18.0,
    this.description = '',
    this.uid,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'status': status,
      'projectId': projectId,
      'isExternal': isExternal,
      'currency': currency,
      'isGstEnabled': isGstEnabled,
      'gstPercentage': gstPercentage,
      'description': description,
      'uid': uid,
    };
  }

  static Invoice fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      clientName: map['clientName'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      status: map['status'],
      projectId: map['projectId'],
      isExternal: map['isExternal'] ?? false,
      currency: map['currency'] ?? 'USD',
      isGstEnabled: map['isGstEnabled'] ?? false,
      gstPercentage: (map['gstPercentage'] as num?)?.toDouble() ?? 18.0,
      description: map['description'] ?? '',
      uid: map['uid'],
    );
  }
}

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 3;

  @override
  Invoice read(BinaryReader reader) {
    String id = reader.readString();
    String clientName = reader.readString();
    double amount = reader.readDouble();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    String status = reader.readString();
    
    // Migration
    String? projectId;
    bool isExternal = false;
    String currency = 'USD';
    
    if (reader.availableBytes > 0) {
      bool hasProjectId = reader.readBool();
      if (hasProjectId) projectId = reader.readString();
      if (reader.availableBytes > 0) isExternal = reader.readBool();
      if (reader.availableBytes > 0) currency = reader.readString();
    }
    
    // Migration for GST
    bool isGstEnabled = false;
    double gstPercentage = 18.0;
    if (reader.availableBytes > 0) isGstEnabled = reader.readBool();
    if (reader.availableBytes > 0) gstPercentage = reader.readDouble();

    // Migration for description
    String description = '';
    if (reader.availableBytes > 0) description = reader.readString();

    return Invoice(
      id: id,
      clientName: clientName,
      amount: amount,
      date: date,
      status: status,
      projectId: projectId,
      isExternal: isExternal,
      currency: currency,
      isGstEnabled: isGstEnabled,
      gstPercentage: gstPercentage,
      description: description,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.clientName);
    writer.writeDouble(obj.amount);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.status);
    
    writer.writeBool(obj.projectId != null);
    if (obj.projectId != null) writer.writeString(obj.projectId!);
    writer.writeBool(obj.isExternal);
    writer.writeString(obj.currency);
    writer.writeBool(obj.isGstEnabled);
    writer.writeDouble(obj.gstPercentage);
    writer.writeString(obj.description);
  }
}
