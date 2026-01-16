import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_repository.dart';

/// Repository for managing proposal data
///
/// Provides CRUD operations for proposals with additional business logic
/// for proposal tracking, client relationships, and conversion analytics.
class ProposalRepository extends HiveRepository<Proposal> {
  @override
  String get boxName => 'proposals';

  /// Get proposals for a specific client (simplified - using clientName)
  Future<List<Proposal>> getProposalsForClient(String clientName) async {
    final proposals = await getAllOnce();
    return proposals.where((proposal) => proposal.clientName == clientName).toList();
  }

  /// Get pending proposals (not accepted or rejected)
  Future<List<Proposal>> getPendingProposals() async {
    final proposals = await getAllOnce();
    return proposals.where((proposal) =>
        proposal.status != 'Accepted' &&
        proposal.status != 'Rejected'
    ).toList();
  }

  /// Get accepted proposals
  Future<List<Proposal>> getAcceptedProposals() async {
    final proposals = await getAllOnce();
    return proposals.where((proposal) => proposal.status == 'Accepted').toList();
  }

  /// Get rejected proposals
  Future<List<Proposal>> getRejectedProposals() async {
    final proposals = await getAllOnce();
    return proposals.where((proposal) => proposal.status == 'Rejected').toList();
  }

  /// Update proposal status
  Future<void> updateProposalStatus(String proposalId, String status) async {
    final proposal = await getById(proposalId);
    if (proposal != null) {
      final updatedProposal = Proposal(
        id: proposal.id,
        clientName: proposal.clientName,
        projectTitle: proposal.projectTitle,
        description: proposal.description,
        estimatedBudget: proposal.estimatedBudget,
        dateSent: proposal.dateSent,
        status: status,
        timeline: proposal.timeline,
        style: proposal.style,
        uid: proposal.uid,
      );
      await save(updatedProposal);
    }
  }

  /// Get expired proposals (simplified - no validUntil in model)
  Future<List<Proposal>> getExpiredProposals() async {
    // Proposal doesn't have validUntil, so return empty list
    return [];
  }

  /// Get proposals expiring soon (simplified - no validUntil in model)
  Future<List<Proposal>> getProposalsExpiringSoon({int days = 7}) async {
    // Proposal doesn't have validUntil, so return empty list
    return [];
  }

  /// Convert proposal to project (when accepted)
  Future<String?> convertProposalToProject(String proposalId) async {
    final proposal = await getById(proposalId);
    if (proposal == null || proposal.status != 'Accepted') {
      return null;
    }

    final projectBox = Hive.box<Project>('projects');
    final projectId = DateTime.now().millisecondsSinceEpoch.toString();

    final newProject = Project(
      id: projectId,
      name: proposal.projectTitle,
      clientName: proposal.clientName,
      budget: proposal.estimatedBudget,
      deadline: proposal.dateSent.add(const Duration(days: 30)), // Default 30 days
      status: 'Not Started',
      estimatedHours: 0, // Default
      currency: 'USD', // Default
      uid: proposal.uid,
    );

    await projectBox.put(projectId, newProject);

    // Update proposal status to converted
    await updateProposalStatus(proposalId, 'Converted to Project');

    return projectId;
  }

  /// Get proposal statistics
  Future<ProposalStats> getProposalStats() async {
    final proposals = await getAllOnce();
    final now = DateTime.now();

    int sentCount = 0;
    int acceptedCount = 0;
    int rejectedCount = 0;
    int expiredCount = 0;
    double totalValue = 0.0;
    double acceptedValue = 0.0;

    final monthlyStats = <DateTime, Map<String, int>>{};

    for (final proposal in proposals) {
      totalValue += proposal.estimatedBudget;

      switch (proposal.status) {
        case 'Pending':
          sentCount++;
          // Simplified - no expired logic without validUntil
          break;
        case 'Accepted':
          acceptedCount++;
          acceptedValue += proposal.estimatedBudget;
          break;
        case 'Rejected':
          rejectedCount++;
          break;
      }

      // Track monthly statistics
      final month = DateTime(proposal.dateSent.year, proposal.dateSent.month);
      monthlyStats[month] ??= {'sent': 0, 'accepted': 0, 'rejected': 0};

      switch (proposal.status) {
        case 'Pending':
          monthlyStats[month]!['sent'] = (monthlyStats[month]!['sent'] ?? 0) + 1;
          break;
        case 'Accepted':
          monthlyStats[month]!['accepted'] = (monthlyStats[month]!['accepted'] ?? 0) + 1;
          break;
        case 'Rejected':
          monthlyStats[month]!['rejected'] = (monthlyStats[month]!['rejected'] ?? 0) + 1;
          break;
      }
    }

    return ProposalStats(
      totalProposals: proposals.length,
      sentCount: sentCount,
      acceptedCount: acceptedCount,
      rejectedCount: rejectedCount,
      expiredCount: expiredCount,
      totalValue: totalValue,
      acceptedValue: acceptedValue,
      monthlyStats: monthlyStats,
    );
  }

  /// Search proposals by title, client, or status
  @override
  Future<List<Proposal>> search(String query) async {
    final allProposals = await getAllOnce();
    final lowercaseQuery = query.toLowerCase();

    return allProposals.where((proposal) {
      return proposal.projectTitle.toLowerCase().contains(lowercaseQuery) ||
             proposal.clientName.toLowerCase().contains(lowercaseQuery) ||
             proposal.status.toLowerCase().contains(lowercaseQuery) ||
             proposal.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get proposals sorted by creation date (newest first)
  Future<List<Proposal>> getProposalsSortedByDate() async {
    final proposals = await getAllOnce();
    proposals.sort((a, b) => b.dateSent.compareTo(a.dateSent));
    return proposals;
  }

  /// Get proposals by value range
  Future<List<Proposal>> getProposalsByValueRange(double minValue, double maxValue) async {
    final proposals = await getAllOnce();
    return proposals.where((proposal) =>
        proposal.estimatedBudget >= minValue &&
        proposal.estimatedBudget <= maxValue
    ).toList();
  }
}

/// Statistics for proposal data
class ProposalStats {
  final int totalProposals;
  final int sentCount;
  final int acceptedCount;
  final int rejectedCount;
  final int expiredCount;
  final double totalValue;
  final double acceptedValue;
  final Map<DateTime, Map<String, int>> monthlyStats;

  const ProposalStats({
    required this.totalProposals,
    required this.sentCount,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.expiredCount,
    required this.totalValue,
    required this.acceptedValue,
    required this.monthlyStats,
  });

  double get acceptanceRate {
    if (sentCount == 0) return 0.0;
    return acceptedCount / sentCount;
  }

  double get averageProposalValue {
    if (totalProposals == 0) return 0.0;
    return totalValue / totalProposals;
  }

  double get conversionValue {
    if (acceptedCount == 0) return 0.0;
    return acceptedValue / acceptedCount;
  }

  bool get hasExpiredProposals => expiredCount > 0;
}