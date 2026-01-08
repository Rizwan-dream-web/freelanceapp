import 'package:hive/hive.dart';

// --- Note Model ---
class Note extends HiveObject {
  String id;
  String content;
  DateTime lastUpdated;
  int colorIndex; // For sticky note colors

  Note({
    required this.id,
    required this.content,
    required this.lastUpdated,
    this.colorIndex = 0,
  });
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

  Client({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.notes,
  });
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

  Proposal({
    required this.id,
    required this.clientName,
    required this.projectTitle,
    required this.description,
    required this.estimatedBudget,
    required this.dateSent,
    this.status = 'Pending',
    this.timeline = '',
  });
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
    if (reader.availableBytes > 0) {
      timeline = reader.readString();
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
  });
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

  TaskItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.isCompleted = false,
    this.totalSeconds = 0,
    this.isRunning = false,
    this.lastStartTime,
  });
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

  Invoice({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.date,
    this.status = 'Pending',
    this.projectId,
    this.isExternal = false,
    this.currency = 'USD',
  });
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

    return Invoice(
      id: id,
      clientName: clientName,
      amount: amount,
      date: date,
      status: status,
      projectId: projectId,
      isExternal: isExternal,
      currency: currency,
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
  }
}
