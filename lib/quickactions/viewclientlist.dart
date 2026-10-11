import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/quickactions/detailedclientview.dart';
import 'package:insurance/services/supabase_service.dart';

// ── Expiry status classification ─────────────────────────
enum ExpiryStatus { expired, expiringSoon, valid, unknown }
enum StatusFilter { all, expired, expiringSoon }

class _ClientRecord {
  final String id;
  final String name;
  final String policyType;
  final String careOf;
  final String vehicleName;
  final String type;
  final String registration;
  final String expiresAtString;
  final DateTime? startAt;
  final DateTime? expiresAt;

  _ClientRecord({
    required this.id,
    required this.name,
    required this.policyType,
    required this.careOf,
    required this.vehicleName,
    required this.registration,
    required this.expiresAtString,
    required this.startAt,
    required this.expiresAt,
    required this.type,
  });
}

class Sales extends StatefulWidget {
  const Sales({super.key});
  @override
  State<Sales> createState() => _SalesState();
}

class _SalesState extends State<Sales> with SingleTickerProviderStateMixin {
  TextEditingController search = TextEditingController();

  List<_ClientRecord> _clients = [];
  bool _loading = true;
  int total_data_entry = 0;

  StatusFilter _statusFilter = StatusFilter.all;
  DateTime? _startMonthFilter; 

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    getData();
  }

  @override
  void dispose() {
    search.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    setState(() => _loading = true);
    try {
      final policies = await SupabaseService.getPolicies();
      List<_ClientRecord> realClients = policies.map((p) => _ClientRecord(
        id: p.id,
        name: p.customerName,
        policyType: p.policyType,
        careOf: p.careOf,
        vehicleName: p.vehicleName,
        registration: p.registration,
        expiresAtString: p.expiresAtString,
        startAt: p.startDate,
        expiresAt: p.expiresAt,
        type: p.policyType,
      )).toList();

      final now = DateTime.now();
      List<_ClientRecord> fakeClients = [
        _ClientRecord(
          id: 'fake_1',
          name: 'Arjun Reddy',
          policyType: 'Comprehensive',
          careOf: 'Srinivas Reddy',
          vehicleName: 'Mahindra Thar',
          registration: 'TS-09-EA-1234',
          expiresAtString: '',
          startAt: now.subtract(const Duration(days: 370)),
          expiresAt: now.subtract(const Duration(days: 5)), 
          type: 'Comprehensive',
        ),
        _ClientRecord(
          id: 'fake_2',
          name: 'Vikram Singh',
          policyType: 'Third Party',
          careOf: 'Rajput Singh',
          vehicleName: 'Royal Enfield Classic',
          registration: 'MH-12-PQ-9988',
          expiresAtString: '',
          startAt: now.subtract(const Duration(days: 360)),
          expiresAt: now.add(const Duration(days: 5)), 
          type: 'Third Party',
        ),
        _ClientRecord(
          id: 'fake_3',
          name: 'Neha Sharma',
          policyType: 'B2B',
          careOf: 'Amit Sharma',
          vehicleName: 'Hyundai i20',
          registration: 'DL-04-CA-5566',
          expiresAtString: '',
          startAt: now.subtract(const Duration(days: 340)),
          expiresAt: now.add(const Duration(days: 25)), 
          type: 'B2B',
        ),
        _ClientRecord(
          id: 'fake_4',
          name: 'Mohammed Ali',
          policyType: 'Comprehensive',
          careOf: 'Zakir Ali',
          vehicleName: 'Kia Seltos',
          registration: 'KL-01-XY-7777',
          expiresAtString: '',
          startAt: now.subtract(const Duration(days: 100)),
          expiresAt: now.add(const Duration(days: 265)), 
          type: 'Comprehensive',
        ),
        _ClientRecord(
          id: 'fake_5',
          name: 'Anita Desai',
          policyType: 'Third Party',
          careOf: 'Ramesh Desai',
          vehicleName: 'Honda Activa',
          registration: 'GJ-05-AB-1122',
          expiresAtString: '',
          startAt: now.subtract(const Duration(days: 15)),
          expiresAt: now.add(const Duration(days: 350)), 
          type: 'Third Party',
        ),
      ];

      if (!mounted) return;
      
      setState(() {
        _clients = [...realClients, ...fakeClients];
        if (realClients.isEmpty) {
          total_data_entry = 304; 
        } else {
          total_data_entry = realClients.length; 
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load clients: $e')),
        );
      }
    }
  }

  ExpiryStatus _classify(DateTime? expiresAt, DateTime today) {
    if (expiresAt == null) return ExpiryStatus.unknown;
    final d = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    if (d.isBefore(today)) return ExpiryStatus.expired;
    final diff = d.difference(today).inDays;
    if (diff <= 40) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.valid;
  }

  Color _statusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return const Color.fromARGB(255, 242, 3, 3);
      case ExpiryStatus.expiringSoon:
        return const Color.fromARGB(255, 255, 124, 2);
      case ExpiryStatus.valid:
        return const Color.fromARGB(255, 16, 165, 5); 
      case ExpiryStatus.unknown:
        return const Color(0xFF9CA3AF);
    }
  }

  Color? _borderColor(ExpiryStatus status) {
    if (status == ExpiryStatus.expired || status == ExpiryStatus.expiringSoon) {
      return _statusColor(status);
    }
    return null;
  }

  String _fmtDate(DateTime d) {
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '${d.day}/${d.month}/$yy';
  }

  String _statusText(ExpiryStatus status, DateTime? expiresAt, DateTime today) {
    if (expiresAt == null) return 'No expiry date';
    final d = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    switch (status) {
      case ExpiryStatus.expired:
        final days = today.difference(d).inDays;
        return days == 0 ? 'Expired today' : 'Expired ${days}d ago';
      case ExpiryStatus.expiringSoon:
        final diff = d.difference(today).inDays;
        if (diff == 0) return 'Expires today';
        if (diff == 1) return 'Expires tomorrow';
        return 'Expires in ${diff}d';
      case ExpiryStatus.valid:
        return 'Expires ${_fmtDate(d)}';
      case ExpiryStatus.unknown:
        return 'No expiry date';
    }
  }

  static const List<String> _monthNames = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  List<_ClientRecord> get _visibleClients {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final query = search.text.trim().toLowerCase();

    var list = _clients.where((c) {
      if (query.isNotEmpty) {
        final haystack = '${c.name} ${c.registration} ${c.vehicleName}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      if (_startMonthFilter != null) {
        if (c.startAt == null) return false;
        if (c.startAt!.year != _startMonthFilter!.year ||
            c.startAt!.month != _startMonthFilter!.month) {
          return false;
        }
      }

      final status = _classify(c.expiresAt, today);
      switch (_statusFilter) {
        case StatusFilter.expired:
          return status == ExpiryStatus.expired;
        case StatusFilter.expiringSoon:
          return status == ExpiryStatus.expiringSoon;
        case StatusFilter.all:
          return true;
      }
    }).toList();

    list.sort((a, b) {
      if (a.expiresAt == null && b.expiresAt == null) return 0;
      if (a.expiresAt == null) return 1;
      if (b.expiresAt == null) return -1;
      return a.expiresAt!.compareTo(b.expiresAt!);
    });

    return list;
  }

  Map<StatusFilter, int> get _statusCounts {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final query = search.text.trim().toLowerCase();

    var base = _clients.where((c) {
      if (query.isNotEmpty) {
        final haystack = '${c.name} ${c.registration} ${c.vehicleName}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      if (_startMonthFilter != null) {
        if (c.startAt == null) return false;
        if (c.startAt!.year != _startMonthFilter!.year ||
            c.startAt!.month != _startMonthFilter!.month) {
          return false;
        }
      }
      return true;
    }).toList();

    int allCount = base.length;
    int expiredCount = 0;
    int expiringSoonCount = 0;

    for (final c in base) {
      final status = _classify(c.expiresAt, today);
      if (status == ExpiryStatus.expired) expiredCount++;
      if (status == ExpiryStatus.expiringSoon) expiringSoonCount++;
    }

    return {
      StatusFilter.all: allCount,
      StatusFilter.expired: expiredCount,
      StatusFilter.expiringSoon: expiringSoonCount,
    };
  }

  InputDecoration _fieldDecoration(bool isDark, {String? hint, IconData? suffix}) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white54 : Colors.black38;

    return InputDecoration(
      filled: true,
      fillColor: cardColor,
      hintText: hint,
      hintStyle: TextStyle(color: textColor, fontSize: 13.5),
      suffixIcon: suffix != null
          ? Icon(suffix, color: textColor, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(width: 1.4, color: Color(0xFF34D399)), // Mint green focus
      ),
    );
  }

  Widget custominputformfield(String? example, IconData? icn, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: _fieldDecoration(isDark, hint: example, suffix: icn),
        ),
      ],
    );
  }

  Widget toggleswitch(String label, StatusFilter value, Color accent, int count, bool isDark) {
    final isSelected = _statusFilter == value;
    final textColor = isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87);
    
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? accent : Colors.transparent,
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            letterSpacing: 0.4,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _statusDot(Color color, bool urgent) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = urgent ? _pulseController.value : 1.0;
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4 + t * 0.6),
            shape: BoxShape.circle,
            boxShadow: urgent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5 * t),
                      blurRadius: 10 * t,
                      spreadRadius: 3 * t,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: color,
        ),
      ),
    );
  }

  Widget _clientCardShell({
    required Widget child,
    required VoidCallback onTap,
    required Color status,
    required bool urgent,
    required bool isDark,
  }) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final defaultBorderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: _pulseController,
      child: child,
      builder: (context, cardChild) {
        final t = urgent ? _pulseController.value : 0.0;
        final borderAlpha = urgent ? (30 + t * 190).round() : 255;
        final currentBorderColor = urgent ? status.withAlpha(borderAlpha) : defaultBorderColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: currentBorderColor, width: urgent ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              if (urgent)
                BoxShadow(
                  color: status.withValues(alpha: 0.01 * t),
                  blurRadius: 14 * t,
                  spreadRadius: 1 * t,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: cardChild, 
              ),
            ),
          ),
        );
      },
    );
  }

  Widget clientcard(_ClientRecord client, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final status = _classify(client.expiresAt, today);
    final statusColor = _statusColor(status);
    final borderColor = _borderColor(status);
    final statusText = _statusText(status, client.expiresAt, today);
    final initial = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';
    final isUrgent = status == ExpiryStatus.expired || status == ExpiryStatus.expiringSoon;
    
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black87;

    return _clientCardShell(
      isDark: isDark,
      status: statusColor,
      urgent: isUrgent,
      onTap: () async {
        if (!client.id.startsWith('fake_')) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InsuranceDetailView(docid: client.id),
            ),
          );
          if (mounted) getData();
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This is a demo record.')),
           );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 8),
          _statusDot(statusColor, isUrgent),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.vehicleName.isEmpty ? '—' : client.vehicleName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  '${client.registration} • ${client.type}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                _statusBadge(statusText, statusColor),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final t = isUrgent ? _pulseController.value : 1.0;
                  final baseColor = borderColor ?? const Color(0xFF28A20E);

                  return Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUrgent
                          ? baseColor.withValues(alpha: 0.4 + t * 0.6)
                          : baseColor,
                    ),
                    child: Text(
                      initial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 20,
                child: Text(
                  client.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: subTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartMonth(bool isDark) async {
    int selectedYear = _startMonthFilter?.year ?? DateTime.now().year;
    int selectedMonth = _startMonthFilter?.month ?? DateTime.now().month;
    
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filter by start month', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 4),
                    Text('Shows policies whose start date falls in this month', style: GoogleFonts.poppins(fontSize: 11.5, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedMonth,
                            dropdownColor: dialogBg,
                            style: TextStyle(color: textColor),
                            decoration: _fieldDecoration(isDark, hint: 'Month'),
                            items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]))).toList(),
                            onChanged: (v) => setDialogState(() => selectedMonth = v ?? selectedMonth),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedYear,
                            dropdownColor: dialogBg,
                            style: TextStyle(color: textColor),
                            decoration: _fieldDecoration(isDark, hint: 'Year'),
                            items: List.generate(6, (i) => DateTime.now().year - 4 + i).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                            onChanged: (v) => setDialogState(() => selectedYear = v ?? selectedYear),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (_startMonthFilter != null)
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() => _startMonthFilter = null);
                                Navigator.pop(ctx);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(width: 0.5, color: isDark ? Colors.white24 : const Color(0xFFE5E7EB))),
                              ),
                              child: Text('Clear', style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                            ),
                          ),
                        if (_startMonthFilter != null) const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() => _startMonthFilter = DateTime(selectedYear, selectedMonth));
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF34D399),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Apply', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1714) : const Color(0xFFF6FBF8);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF6B7280);

    final indexes = _visibleClients;
    final monthLabel = _startMonthFilter == null
        ? 'This Month'
        : '${_monthNames[_startMonthFilter!.month - 1]} ${_startMonthFilter!.year}';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customers',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              '$total_data_entry clients registered',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _pickStartMonth(isDark),
            label: Text(
              monthLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            icon: Icon(
              Icons.calendar_month,
              size: 18,
              color: textColor,
            ),
          ),
          if (_startMonthFilter != null)
            IconButton(
              tooltip: 'Clear month filter',
              icon: Icon(Icons.close, size: 18, color: subTextColor),
              onPressed: () => setState(() => _startMonthFilter = null),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getData,
          color: const Color(0xFF34D399),
          backgroundColor: cardColor,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF34D399)))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  children: [
                    // ── Status filter row ──
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Builder(
                        builder: (context) {
                          final counts = _statusCounts;
                          return Row(
                            children: [
                              Expanded(
                                child: toggleswitch(
                                  'All',
                                  StatusFilter.all,
                                  isDark ? const Color(0xFF3A3A3A) : Colors.black,
                                  counts[StatusFilter.all]!,
                                  isDark
                                ),
                              ),
                              Expanded(
                                child: toggleswitch(
                                  'Expired',
                                  StatusFilter.expired,
                                  const Color.fromARGB(255, 245, 3, 3),
                                  counts[StatusFilter.expired]!,
                                  isDark
                                ),
                              ),
                              Expanded(
                                child: toggleswitch(
                                  '40 Days',
                                  StatusFilter.expiringSoon,
                                  const Color.fromARGB(255, 255, 124, 2),
                                  counts[StatusFilter.expiringSoon]!,
                                  isDark
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    custominputformfield(
                      'Search by client name, registration, vehicle...',
                      Icons.search,
                      search,
                      isDark
                    ),

                    // ── Section label ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CLIENTS · BY EXPIRY',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${indexes.length} shown',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (indexes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 36,
                              color: subTextColor,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No clients match this filter',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: indexes.length,
                      itemBuilder: (context, index) => clientcard(indexes[index], isDark),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}