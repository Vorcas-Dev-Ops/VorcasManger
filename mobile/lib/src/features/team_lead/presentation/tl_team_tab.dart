import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../../core/common_widgets/common_avatar.dart';
import 'squad_member_detail_screen.dart';
import 'tl_notifiers.dart';

class TlTeamTab extends ConsumerStatefulWidget {
  const TlTeamTab({super.key});

  @override
  ConsumerState<TlTeamTab> createState() => _TlTeamTabState();
}

class _TlTeamTabState extends ConsumerState<TlTeamTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final squadAsync = ref.watch(tlSquadProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: squadAsync.when(
        data: (members) {
          final filteredMembers = members.where((m) {
            final name = (m['name'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Squad\nDirectory', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('SQUAD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        Text('${members.length} MEMBERS', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search squad members...',
                    hintStyle: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: SuperAdminTheme.textSecondary, size: 20),
                    filled: true,
                    fillColor: SuperAdminTheme.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: filteredMembers.isEmpty
                    ? const Center(child: Text('No squad members found', style: TextStyle(color: SuperAdminTheme.textSecondary)))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final m = filteredMembers[index];
                          return _SquadMemberGridCard(
                            member: m,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SquadMemberDetailScreen(
                                    member: m,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _SquadMemberGridCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onTap;

  const _SquadMemberGridCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = member['name'] ?? 'Unknown';
    final role = member['role']?.toString().toUpperCase() ?? 'ENGINEER';
    final avatarUrl = member['avatarUrl'];
    final isOnline = member['status'] == 'ACTIVE' || member['status'] == 'ONLINE';

    return Container(
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SuperAdminTheme.surfaceLighter),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CommonAvatar(
                    radius: 80,
                    imageUrl: member['profile_picture_url'] ?? avatarUrl,
                    isSquare: true,
                    borderRadius: 0,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, SuperAdminTheme.surfaceCard.withOpacity(0.9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? SuperAdminTheme.statusPositive : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: SuperAdminTheme.backgroundBlack, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 30,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: SuperAdminTheme.backgroundBlack,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text('VIEW PROFILE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
