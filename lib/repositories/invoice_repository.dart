import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_repository.dart';

/// Repository for managing invoice data
///
/// Provides CRUD operations for invoices with additional business logic
/// for financial tracking, payment status, and client relationships.
class InvoiceRepository extends HiveRepository<Invoice> {
  @override
  String get boxName => 'invoices';

  /// Get invoices for a specific project
  Future<List<Invoice>> getInvoicesForProject(String projectId) async {
    final invoices = await getAllOnce();
    return invoices.where((invoice) => invoice.projectId == projectId).toList();
  }

  /// Get invoices for a specific client
  Future<List<Invoice>> getInvoicesForClient(String clientId) async {
    final invoices = await getAllOnce();
    final projectBox = Hive.box<Project>('projects');

    // Get all project IDs for this client
    final clientProjectIds = projectBox.values
        .where((project) => project.clientId == clientId)
        .map((project) => project.id)
        .toSet();

    return invoices
        .where((invoice) => clientProjectIds.contains(invoice.projectId))
        .toList();
  }

  /// Get unpaid invoices
  Future<List<Invoice>> getUnpaidInvoices() async {
    final invoices = await getAllOnce();
    return invoices.where((invoice) => invoice.status != 'Paid').toList();
  }

  /// Get paid invoices
  Future<List<Invoice>> getPaidInvoices() async {
    final invoices = await getAllOnce();
    return invoices.where((invoice) => invoice.status == 'Paid').toList();
  }

  /// Get overdue invoices
  Future<List<Invoice>> getOverdueInvoices() async {
    final invoices = await getAllOnce();
    final now = DateTime.now();

    return invoices.where((invoice) =>
        invoice.date.isBefore(now) &&
        invoice.status != 'Paid'
    ).toList();
  }

  /// Get invoices due soon (within next 7 days)
  Future<List<Invoice>> getInvoicesDueSoon({int days = 7}) async {
    final invoices = await getAllOnce();
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    return invoices.where((invoice) =>
        invoice.date.isAfter(now) &&
        invoice.date.isBefore(futureDate) &&
        invoice.status != 'Paid'
    ).toList();
  }

  /// Mark invoice as paid
  Future<void> markInvoiceAsPaid(String invoiceId, {DateTime? paidAt}) async {
    final invoice = await getById(invoiceId);
    if (invoice != null) {
      final updatedInvoice = Invoice(
        id: invoice.id,
        clientName: invoice.clientName,
        amount: invoice.amount,
        date: invoice.date,
        status: 'Paid',
        projectId: invoice.projectId,
        isExternal: invoice.isExternal,
        currency: invoice.currency,
        isGstEnabled: invoice.isGstEnabled,
        gstPercentage: invoice.gstPercentage,
        description: invoice.description,
        uid: invoice.uid,
      );
      await save(updatedInvoice);
    }
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    final invoice = await getById(invoiceId);
    if (invoice != null) {
      final updatedInvoice = Invoice(
        id: invoice.id,
        clientName: invoice.clientName,
        amount: invoice.amount,
        date: invoice.date,
        status: status,
        projectId: invoice.projectId,
        isExternal: invoice.isExternal,
        currency: invoice.currency,
        isGstEnabled: invoice.isGstEnabled,
        gstPercentage: invoice.gstPercentage,
        description: invoice.description,
        uid: invoice.uid,
      );
      await save(updatedInvoice);
    }
  }

  /// Get invoice statistics
  Future<InvoiceStats> getInvoiceStats() async {
    final invoices = await getAllOnce();
    final now = DateTime.now();

    double totalInvoiced = 0.0;
    double totalPaid = 0.0;
    double totalOutstanding = 0.0;

    int overdueCount = 0;
    int paidCount = 0;
    int unpaidCount = 0;

    final monthlyRevenue = <DateTime, double>{};

    for (final invoice in invoices) {
      totalInvoiced += invoice.amount;

      if (invoice.status == 'Paid') {
        totalPaid += invoice.amount;
        paidCount++;
      } else {
        totalOutstanding += invoice.amount;
        unpaidCount++;

        if (invoice.date.isBefore(now)) {
          overdueCount++;
        }
      }

      // Track monthly revenue
      if (invoice.status == 'Paid') {
        final month = DateTime(
          invoice.date.year,
          invoice.date.month,
        );
        monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + invoice.amount;
      }
    }

    return InvoiceStats(
      totalInvoices: invoices.length,
      totalInvoiced: totalInvoiced,
      totalPaid: totalPaid,
      totalOutstanding: totalOutstanding,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
      overdueCount: overdueCount,
      monthlyRevenue: monthlyRevenue,
    );
  }

  /// Search invoices by project, client, or status
  @override
  Future<List<Invoice>> search(String query) async {
    final allInvoices = await getAllOnce();
    final lowercaseQuery = query.toLowerCase();

    return allInvoices.where((invoice) {
      return invoice.clientName.toLowerCase().contains(lowercaseQuery) ||
             invoice.status.toLowerCase().contains(lowercaseQuery) ||
             invoice.id.toLowerCase().contains(lowercaseQuery) ||
             invoice.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get invoices sorted by due date
  Future<List<Invoice>> getInvoicesSortedByDueDate() async {
    final invoices = await getAllOnce();
    invoices.sort((a, b) => a.date.compareTo(b.date));
    return invoices;
  }

  /// Get invoices within date range
  Future<List<Invoice>> getInvoicesInDateRange(DateTime start, DateTime end) async {
    final invoices = await getAllOnce();
    return invoices.where((invoice) =>
        invoice.date.isAfter(start) &&
        invoice.date.isBefore(end)
    ).toList();
  }
}

/// Statistics for invoice data
class InvoiceStats {
  final int totalInvoices;
  final double totalInvoiced;
  final double totalPaid;
  final double totalOutstanding;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;
  final Map<DateTime, double> monthlyRevenue;

  const InvoiceStats({
    required this.totalInvoices,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.paidCount,
    required this.unpaidCount,
    required this.overdueCount,
    required this.monthlyRevenue,
  });

  double get paymentRate {
    if (totalInvoices == 0) return 0.0;
    return paidCount / totalInvoices;
  }

  double get outstandingPercentage {
    if (totalInvoiced == 0) return 0.0;
    return totalOutstanding / totalInvoiced;
  }

  bool get hasOverdueInvoices => overdueCount > 0;
}