import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../../core/common_widgets/common_avatar.dart';
import 'tl_notifiers.dart';
import 'squad_member_detail_screen.dart';

class TlTaskReportScreen extends ConsumerWidget {
  const TlTaskReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(tlSquadProgressProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Detailed Task Report', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: SuperAdminTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: progressAsync.when(
        data: (squadProgress) {
          if (squadProgress.isEmpty) {
            return const Center(child: Text('No squad members found', style: TextStyle(color: SuperAdminTheme.textSecondary)));
          }

          final totalOverdue = squadProgress.fold<int>(0, (sum, item) => sum + (item['overdue'] as int));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Summary Header
              _buildSummaryHeader(totalOverdue),
              const SizedBox(height: 32),

              const Text('SQUAD PROGRESS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 16),

              ...squadProgress.map((member) => _MemberProgressCard(member: member)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (e, st) => Center(child: Text('Error loading progress: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildSummaryHeader(int totalOverdue) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SuperAdminTheme.primaryOrange, SuperAdminTheme.primaryOrange.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: SuperAdminTheme.primaryOrange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.white, size: 32),
              if (totalOverdue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('$totalOverdue OVERDUE', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Squad Performance', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Keep track of your team\'s efficiency and critical deadlines.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
          ),
        ],
      )
    );
  }
}

class _MemberProgressCard extends StatelessWidget {
  final Map<String, dynamic> member;
  const _MemberProgressCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final percentage = member['percentage'] as int;
    final overdue = member['overdue'] as int;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SquadMemberDetailScreen(member: member),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SuperAdminTheme.surfaceLighter),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CommonAvatar(
                  radius: 20,
                  imageUrl: member['profile_picture_url'],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member['name'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${member['done']} / ${member['total']} Tasks Completed', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$percentage%', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (overdue > 0)
                      Text('$overdue Overdue', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: SuperAdminTheme.backgroundBlack,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 70 ? SuperAdminTheme.statusPositive : (percentage > 30 ? SuperAdminTheme.primaryOrange : Colors.red),
                ),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
