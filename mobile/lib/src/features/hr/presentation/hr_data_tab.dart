import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../super_admin/data/super_admin_providers.dart';

class HrDataTab extends ConsumerStatefulWidget {
  const HrDataTab({super.key});

  @override
  ConsumerState<HrDataTab> createState() => _HrDataTabState();
}

class _HrDataTabState extends ConsumerState<HrDataTab> {
  bool _isGenerating = false;
  String _selectedScope = 'Full Workforce';
  String? _selectedDeptId;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 90)),
    end: DateTime.now(),
  );

  String get _dateRangeString {
    final start = DateFormat('MMM yyyy').format(_selectedDateRange.start);
    final end = DateFormat('MMM yyyy').format(_selectedDateRange.end);
    return '$start - $end';
  }

  Future<void> _selectDateRange() async {
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomDateRangeSheet(initialRange: _selectedDateRange),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Future<void> _generateReport(String title) async {
    setState(() => _isGenerating = true);
    
    try {
      // 1. Fetch Actual Data
      List<List<String>> tableData = [];
      String reportSubtitle = "";
      
      if (title == 'Headcount Report') {
        final dashboardData = await ref.read(superAdminDashboardProvider.future);
        final departments = (dashboardData['departments'] as List? ?? []);
        reportSubtitle = "Current workforce distribution across all departments.";
        tableData.add(['Department', 'Headcount', 'Status']);
        for (var dept in departments) {
          tableData.add([
            dept['name'] ?? 'Unknown',
            (dept['employee_count'] ?? 0).toString(),
            'ACTIVE'
          ]);
        }
      } else if (title == 'Attendance Audit') {
        final attendanceStats = await ref.read(superAdminAttendanceStatsProvider.future);
        reportSubtitle = "Operational flow and workforce presence metrics.";
        tableData.add(['Date', 'Present', 'Late', 'Absent']);
        // Take last 5 days
        for (var stat in attendanceStats.take(7)) {
          tableData.add([
            stat['date'] ?? 'N/A',
            (stat['present'] ?? 0).toString(),
            (stat['late'] ?? 0).toString(),
            (stat['absent'] ?? 0).toString(),
          ]);
        }
      } else if (title == 'Leave Liability') {
        final pendingLeaves = await ref.read(superAdminPendingLeavesProvider.future);
        reportSubtitle = "Accrued leave balances and upcoming fiscal liabilities.";
        tableData.add(['Employee', 'Leave Type', 'Duration', 'Status']);
        for (var leave in pendingLeaves.take(10)) {
          int duration = 1;
          try {
            if (leave['start_date'] != null && leave['end_date'] != null) {
              final start = DateTime.parse(leave['start_date']);
              final end = DateTime.parse(leave['end_date']);
              duration = end.difference(start).inDays + 1;
            }
          } catch (_) {}
          
          tableData.add([
            leave['employee_name'] ?? 'N/A',
            leave['leave_type'] ?? 'General',
            "$duration Days",
            (leave['status'] ?? 'PENDING').toString().toUpperCase(),
          ]);
        }
      } else {
        // Custom report using selected filters
        final dashboardData = await ref.read(superAdminDashboardProvider.future);
        final metrics = dashboardData['metrics'] as Map<String, dynamic>? ?? {};
        final depts = (dashboardData['departments'] as List? ?? []);
        
        int scopeCount = metrics['totalEmployees'] ?? 0;
        if (_selectedScope != 'Full Workforce') {
          final selectedDept = depts.firstWhere((d) => d['name'] == _selectedScope, orElse: () => null);
          scopeCount = selectedDept?['employee_count'] ?? 0;
        }

        reportSubtitle = "Custom aggregated workforce data for $_selectedScope.";
        tableData = [
          ['Metric Category', 'Measured Value', 'Context'],
          ['Personnel Scope', '$scopeCount', _selectedScope.toUpperCase()],
          ['Attendance Rate', '${metrics['presenceRate'] ?? 0}%', 'Operational'],
          ['Active Tasks', '${metrics['activeTasks'] ?? 0}', 'Workload'],
          ['Pending Leaves', '${metrics['pendingLeaves'] ?? 0}', 'Fiscal'],
          ['Reporting Range', '${_selectedDateRange.duration.inDays} Days', 'Temporal'],
        ];
      }

      // 2. Load Logo
      final ByteData logoBytes = await rootBundle.load('assets/images/logo.png');
      final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // 3. Create PDF
      final pdf = pw.Document();
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);
      final filenameDate = DateFormat('yyyyMMdd_HHmm').format(now);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('VORCAS TECH LAB', 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20, color: PdfColors.orange800)),
                        pw.Text('HUMAN RESOURCES DIVISION', 
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      height: 50,
                      width: 50,
                      child: pw.Image(logoImage),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text(title.toUpperCase(), 
                  style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(reportSubtitle, 
                  style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                pw.SizedBox(height: 12),
                pw.Text('GENERATED ON: $formattedDate', 
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 24),
                pw.Divider(thickness: 2, color: PdfColors.orange),
                pw.SizedBox(height: 24),
                
                pw.Text('DATA ARCHIVE SUMMARY', 
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.orange900),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                  },
                ),
                
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CONFIDENTIAL DOCUMENT \u2022 VORCAS MANAGER v1.0', 
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                    pw.Text('PAGE 1 OF 1', 
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      if (mounted) {
        setState(() => _isGenerating = false);
        
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: '${title.replaceAll(' ', '_')}_$filenameDate',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              const Text('The Archive Analytics', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 12),
              

              // Standard Reports
              _StandardReportCard(
                category: 'WORKFORCE STRUCTURE',
                title: 'Headcount Report',
                bgIcon: Icons.people,
                onGenerate: () => _generateReport('Headcount Report'),
              ),
              const SizedBox(height: 16),
              _StandardReportCard(
                category: 'OPERATIONAL FLOW',
                title: 'Attendance Audit',
                bgIcon: Icons.timer,
                onGenerate: () => _generateReport('Attendance Audit'),
              ),
              const SizedBox(height: 16),
              _StandardReportCard(
                category: 'FISCAL COMPLIANCE',
                title: 'Leave Liability',
                bgIcon: Icons.account_balance_wallet,
                onGenerate: () => _generateReport('Leave Liability'),
              ),
              const SizedBox(height: 32),

              // Custom Reporting Engine
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Custom Reporting\nEngine', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: 24),

                    const Text('DATA SCOPE', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: SuperAdminTheme.backgroundBlack,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SuperAdminTheme.surfaceLighter),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedScope,
                          dropdownColor: SuperAdminTheme.surfaceCard,
                          icon: const Icon(Icons.keyboard_arrow_down, color: SuperAdminTheme.textSecondary, size: 16),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: [
                            const DropdownMenuItem(value: 'Full Workforce', child: Text('Full Workforce')),
                            ...ref.watch(superAdminDepartmentsProvider).when(
                              data: (depts) => depts.map((d) => DropdownMenuItem(
                                value: d['name'] as String,
                                child: Text(d['name'] as String),
                              )).toList(),
                              loading: () => [],
                              error: (_, __) => [],
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedScope = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('TIME DIMENSION', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: SuperAdminTheme.backgroundBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: SuperAdminTheme.surfaceLighter),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: SuperAdminTheme.primaryOrange, size: 14),
                                const SizedBox(width: 8),
                                Text(_dateRangeString, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                            const Icon(Icons.edit, color: SuperAdminTheme.textSecondary, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _generateReport('Custom Analytics Report'),
                        icon: const Icon(Icons.download, color: Colors.white, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SuperAdminTheme.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        label: const Text('EXPORT CSV/PDF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
          if (_isGenerating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange),
              ),
            ),
        ],
      ),
    );
  }
}

class _StandardReportCard extends StatelessWidget {
  final String category;
  final String title;
  final IconData bgIcon;
  final VoidCallback onGenerate;

  const _StandardReportCard({required this.category, required this.title, required this.bgIcon, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(bgIcon, size: 120, color: SuperAdminTheme.surfaceLighter.withOpacity(0.1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: onGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SuperAdminTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('GENERATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchiveItem extends StatelessWidget {
  final IconData icon;
  final String filename;
  final String timestamp;
  final bool isOutlined;

  const _ArchiveItem({required this.icon, required this.filename, required this.timestamp, this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading $filename...')));
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOutlined ? Colors.transparent : SuperAdminTheme.surfaceCard,
              border: isOutlined ? Border.all(color: SuperAdminTheme.surfaceLighter) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: SuperAdminTheme.primaryOrange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filename, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(timestamp, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CustomDateRangeSheet extends StatefulWidget {
  final DateTimeRange initialRange;

  const _CustomDateRangeSheet({required this.initialRange});

  @override
  State<_CustomDateRangeSheet> createState() => _CustomDateRangeSheetState();
}

class _CustomDateRangeSheetState extends State<_CustomDateRangeSheet> {
  late DateTimeRange _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.initialRange;
  }

  void _setPreset(int days) {
    setState(() {
      _currentRange = DateTimeRange(
        start: DateTime.now().subtract(Duration(days: days)),
        end: DateTime.now(),
      );
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _currentRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: SuperAdminTheme.primaryOrange,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1A1A),
              onSurface: Colors.white,
              onSurfaceVariant: Colors.white,
              primaryContainer: SuperAdminTheme.primaryOrange.withOpacity(0.2),
              onPrimaryContainer: Colors.white,
              secondary: SuperAdminTheme.primaryOrange,
              onSecondary: Colors.white,
              secondaryContainer: SuperAdminTheme.primaryOrange.withOpacity(0.2),
              onSecondaryContainer: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _currentRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SELECT TIME DIMENSION', 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: SuperAdminTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Define the temporal scope for your data module.', 
            style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 32),
          
          const Text('QUICK PRESETS', 
            style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PresetChip(label: 'Last 7 Days', isSelected: false, onTap: () => _setPreset(7)),
              _PresetChip(label: 'Last 30 Days', isSelected: false, onTap: () => _setPreset(30)),
              _PresetChip(label: 'Last 90 Days', isSelected: false, onTap: () => _setPreset(90)),
              _PresetChip(label: 'Year to Date', isSelected: false, onTap: () {
                setState(() {
                  _currentRange = DateTimeRange(
                    start: DateTime(DateTime.now().year, 1, 1),
                    end: DateTime.now(),
                  );
                });
              }),
            ],
          ),
          const SizedBox(height: 32),
          
          const Text('CUSTOM SCOPE', 
            style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickCustomRange,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SuperAdminTheme.backgroundBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SuperAdminTheme.surfaceLighter),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: SuperAdminTheme.primaryOrange),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selected Range', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(_currentRange.start)} - ${DateFormat('MMM dd, yyyy').format(_currentRange.end)}',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: SuperAdminTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _currentRange),
              style: ElevatedButton.styleFrom(
                backgroundColor: SuperAdminTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('APPLY DIMENSION', 
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? SuperAdminTheme.primaryOrange.withOpacity(0.1) : SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceLighter),
        ),
        child: Text(label, 
          style: TextStyle(color: isSelected ? SuperAdminTheme.primaryOrange : Colors.white, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
