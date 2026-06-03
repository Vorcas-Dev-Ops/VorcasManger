import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../leave/presentation/leave_screen.dart';
import 'employee_notifiers.dart';

class EmpLeaveTab extends ConsumerStatefulWidget {
  const EmpLeaveTab({super.key});

  @override
  ConsumerState<EmpLeaveTab> createState() => _EmpLeaveTabState();
}

class _EmpLeaveTabState extends ConsumerState<EmpLeaveTab> {
  String _selectedLeaveType = 'Annual Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  int _selectedTab = 0;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: SuperAdminTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: SuperAdminTheme.primaryOrange,
              onPrimary: Colors.white,
              surface: SuperAdminTheme.surfaceCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitApplication() async {
    if (_startDate == null || _endDate == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final Map<String, dynamic> leaveData = {
      'leave_type': _selectedLeaveType,
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
      'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
      'reason': _reasonController.text,
    };

    try {
      await ref.read(leaveNotifierProvider.notifier).requestLeave(leaveData);
      
      if (mounted) {
        setState(() {
          _startDate = null;
          _endDate = null;
          _reasonController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showApplyForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SuperAdminTheme.backgroundBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apply for Leave', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('LEAVE TYPE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: _selectedLeaveType,
                  isExpanded: true,
                  dropdownColor: SuperAdminTheme.surfaceCard,
                  underline: const SizedBox(),
                  items: ['Annual Leave', 'Sick Leave', 'Casual Leave'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() => _selectedLeaveType = val);
                      setState(() => _selectedLeaveType = val);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START DATE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            await _selectDate(context, true);
                            setSheetState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startDate == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(_startDate!),
                                  style: TextStyle(color: _startDate == null ? SuperAdminTheme.textSecondary : Colors.white, fontSize: 14),
                                ),
                                const Icon(Icons.calendar_today, color: SuperAdminTheme.textSecondary, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('END DATE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            await _selectDate(context, false);
                            setSheetState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endDate == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(_endDate!),
                                  style: TextStyle(color: _endDate == null ? SuperAdminTheme.textSecondary : Colors.white, fontSize: 14),
                                ),
                                const Icon(Icons.calendar_today, color: SuperAdminTheme.textSecondary, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('REASON FOR ABSENCE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Brief explanation...',
                  hintStyle: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: SuperAdminTheme.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _submitApplication();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  label: const Text('SUBMIT APPLICATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SuperAdminTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 40,
            color: isSelected ? SuperAdminTheme.primaryOrange : Colors.transparent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = ref.watch(leaveBalancesProvider);
    final history = ref.watch(leaveHistoryProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Leave Management', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: SuperAdminTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: SuperAdminTheme.primaryOrange, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaveBalancesProvider);
          ref.invalidate(leaveHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Balances Grid
            balances.when(
              data: (balanceList) {
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    ...balanceList.map((b) {
                      final title = b['type'].toString().toUpperCase();
                      return _BalanceBox(
                        title: title, 
                        value: b['balance'].toString().padLeft(2, '0'), 
                        unit: b['unit'].toString(),
                        valueColor: title.contains('PENDING') ? SuperAdminTheme.primaryOrange : Colors.white,
                      );
                    }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
            // Apply for Leave Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _showApplyForm(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('APPLY FOR LEAVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SuperAdminTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Tabs Section
            Row(
              children: [
                _buildTab('PENDING', 0),
                const SizedBox(width: 24),
                _buildTab('APPROVED', 1),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Content
            history.when(
              data: (historyList) {
                final filteredList = _selectedTab == 0
                    ? historyList.where((l) => l['status'].toString().startsWith('PENDING')).toList()
                    : historyList.where((l) => l['status'].toString() == 'APPROVED').toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No records found', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                  ));
                }

                return Column(
                  children: filteredList.map((l) {
                    final status = l['status'].toString();
                    Color color;
                    if (status.startsWith('PENDING')) {
                      color = SuperAdminTheme.primaryOrange;
                    } else if (status == 'APPROVED') color = Colors.green;
                    else color = Colors.red;

                    return _HistoryCard(
                      title: l['leave_type'].toString(),
                      subtitle: '${l['start_date']} to ${l['end_date']}',
                      status: status,
                      statusColor: color,
                      icon: Icons.calendar_today,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaveScreen()),
                );
              },
              child: const Text(
                'LEAVE HISTORY',
                style: TextStyle(
                  color: SuperAdminTheme.primaryOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Completed History
            history.when(
              data: (historyList) {
                final completedList = historyList.where((l) => l['status'].toString() == 'APPROVED' || l['status'].toString() == 'REJECTED').toList();
                if (completedList.isEmpty) {
                   return const SizedBox.shrink();
                }
                return Column(
                  children: completedList.map((l) {
                    final status = l['status'].toString();
                    Color color = status == 'APPROVED' ? Colors.green : Colors.red;

                    return _HistoryCard(
                      title: l['leave_type'].toString(),
                      subtitle: '${l['start_date']} to ${l['end_date']}',
                      status: status,
                      statusColor: color,
                      icon: Icons.history,
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 40),

            // Policy Update Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SuperAdminTheme.backgroundBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SuperAdminTheme.primaryOrange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Icon(Icons.info, color: SuperAdminTheme.primaryOrange, size: 24),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: const [
                         Text('LEAVE POLICY UPDATE', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                         SizedBox(height: 8),
                         Text('Please ensure all leave requests are submitted at least 48 hours in advance. For medical leave longer than 3 days, a valid physician\'s certificate is required upon return.', style: TextStyle(color: Colors.white, fontSize: 12, height: 1.5)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _BalanceBox extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color valueColor;

  const _BalanceBox({required this.title, required this.value, required this.unit, this.valueColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SuperAdminTheme.backgroundBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuperAdminTheme.surfaceCard, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
           Text(title, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
           const SizedBox(height: 4),
           Row(
             crossAxisAlignment: CrossAxisAlignment.baseline,
             textBaseline: TextBaseline.alphabetic,
             children: [
               Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(width: 4),
               Text(unit, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
             ],
           ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData icon;

  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, shape: BoxShape.circle),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(status.replaceAll('_', ' '), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }
}


