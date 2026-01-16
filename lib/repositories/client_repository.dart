import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_repository.dart';

/// Repository for managing client data
///
/// Provides CRUD operations for clients with additional business logic
/// specific to client management.
class ClientRepository extends HiveRepository<Client> {
  @override
  String get boxName => 'clients';

  /// Get clients sorted by name
  Future<List<Client>> getClientsSortedByName() async {
    final clients = await getAllOnce();
    clients.sort((a, b) => a.name.compareTo(b.name));
    return clients;
  }

  /// Search clients by name or company
  @override
  Future<List<Client>> search(String query) async {
    final allClients = await getAllOnce();
    final lowercaseQuery = query.toLowerCase();

    return allClients.where((client) {
      return client.name.toLowerCase().contains(lowercaseQuery) ||
             client.company.toLowerCase().contains(lowercaseQuery) ||
             client.email.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get clients with active projects
  Future<List<Client>> getClientsWithProjects() async {
    final clients = await getAllOnce();
    final projectBox = Hive.box<Project>('projects');

    final clientIdsWithProjects = projectBox.values
        .map((project) => project.clientId)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    return clients
        .where((client) => clientIdsWithProjects.contains(client.id))
        .toList();
  }

  /// Get client statistics
  Future<ClientStats> getClientStats() async {
    final clients = await getAllOnce();
    final projectBox = Hive.box<Project>('projects');
    final invoiceBox = Hive.box<Invoice>('invoices');

    int totalProjects = 0;
    double totalRevenue = 0.0;

    for (final client in clients) {
      final clientProjects = projectBox.values
          .where((project) => project.clientId == client.id)
          .toList();

      totalProjects += clientProjects.length;

      for (final project in clientProjects) {
        final projectInvoices = invoiceBox.values
            .where((invoice) => invoice.projectId == project.id)
            .toList();

        for (final invoice in projectInvoices) {
          totalRevenue += invoice.amount;
        }
      }
    }

    return ClientStats(
      totalClients: clients.length,
      totalProjects: totalProjects,
      totalRevenue: totalRevenue,
    );
  }
}

/// Statistics for client data
class ClientStats {
  final int totalClients;
  final int totalProjects;
  final double totalRevenue;

  const ClientStats({
    required this.totalClients,
    required this.totalProjects,
    required this.totalRevenue,
  });

  double get averageRevenuePerClient {
    if (totalClients == 0) return 0.0;
    return totalRevenue / totalClients;
  }

  double get averageProjectsPerClient {
    if (totalClients == 0) return 0.0;
    return totalProjects / totalClients;
  }
}