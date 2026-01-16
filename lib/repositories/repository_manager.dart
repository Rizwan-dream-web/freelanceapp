import 'client_repository.dart';
import 'project_repository.dart';
import 'task_repository.dart';
import 'invoice_repository.dart';
import 'proposal_repository.dart';
import 'settings_repository.dart';

/// Service locator for repositories
///
/// Provides centralized access to all repository instances.
/// This ensures consistent repository usage throughout the app.
class RepositoryManager {
  static final RepositoryManager _instance = RepositoryManager._internal();

  factory RepositoryManager() => _instance;

  RepositoryManager._internal();

  // Repository instances
  late final ClientRepository _clientRepository;
  late final ProjectRepository _projectRepository;
  late final TaskRepository _taskRepository;
  late final InvoiceRepository _invoiceRepository;
  late final ProposalRepository _proposalRepository;
  late final SettingsRepository _settingsRepository;

  // Getters for repositories
  ClientRepository get clients => _clientRepository;
  ProjectRepository get projects => _projectRepository;
  TaskRepository get tasks => _taskRepository;
  InvoiceRepository get invoices => _invoiceRepository;
  ProposalRepository get proposals => _proposalRepository;
  SettingsRepository get settings => _settingsRepository;

  /// Initialize all repositories
  ///
  /// This should be called after Hive initialization
  void initialize() {
    _clientRepository = ClientRepository();
    _projectRepository = ProjectRepository();
    _taskRepository = TaskRepository();
    _invoiceRepository = InvoiceRepository();
    _proposalRepository = ProposalRepository();
    _settingsRepository = SettingsRepository();
  }

  /// Dispose of all repositories
  ///
  /// Clean up resources when the app is closing
  void dispose() {
    // Hive repositories don't need explicit disposal
    // as Hive handles box closing automatically
  }
}

/// Global repository manager instance
final repositoryManager = RepositoryManager();