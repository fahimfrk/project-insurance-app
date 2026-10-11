import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/quickactions/detailedclientview.dart';
import 'package:insurance/services/supabase_service.dart';

// ── Expiry status classification ─────────────────────────
// expiringSoon = expires within the next 40 days
enum ExpiryStatus { expired, expiringSoon, valid, unknown }

// ── Status filter (drives the toggle row) ────────────────
enum StatusFilter { all, expired, expiringSoon }

// ── Single client/policy record ──────────────────────────
// Replaces the old parallel-array model (users[i], time[i], ...),
// which was unreliable because getData() pushed two values
// (expiresAt AND startAt) into the same `time`/`rawDates` lists,
// shifting every index after the first record.
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

  // ── Data ───────────────────────────────────────────────
  List<_ClientRecord> _clients = [];
  bool _loading = true;
  int total_data_entry = 0;

  // ── Filter state ───────────────────────────────────────
  StatusFilter _statusFilter = StatusFilter.all;
  DateTime? _startMonthFilter; // year+month only; null = all time

  // ── Shared pulse animation for the client-card status dot ──
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

  // ── Fetch + parse with Supabase ──
  Future<void> getData() async {
    setState(() => _loading = true);
    try {
      final policies = await SupabaseService.getPolicies();
      if (!mounted) return;
      setState(() {
        _clients = policies.map((p) => _ClientRecord(
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
        total_data_entry = _clients.length;
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

  // ── Status classification ─────────────────────────────
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
        return const Color.fromARGB(255, 242, 3, 3); // red
      case ExpiryStatus.expiringSoon:
        return const Color.fromARGB(255, 255, 124, 2); // orange
      case ExpiryStatus.valid:
        return const Color.fromARGB(255, 16, 165, 5); // neutral grey (no green)
      case ExpiryStatus.unknown:
        return const Color(0xFF9CA3AF); // grey
    }
  }

  // Only expired / expiring-soon clients get a coloured border
  Color? _borderColor(ExpiryStatus status) {
    if (status == ExpiryStatus.expired || status == ExpiryStatus.expiringSoon) {
      return _statusColor(status);
    }
    return null;
  }

  // e.g. 23/9/26
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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // ── Search + status + start-month filter, then expiry-order sort ──
  List<_ClientRecord> get _visibleClients {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final query = search.text.trim().toLowerCase();

    var list = _clients.where((c) {
      if (query.isNotEmpty) {
        final haystack = '${c.name} ${c.registration} ${c.vehicleName}'
            .toLowerCase();
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

    // Most urgent (soonest expiry) first. Records with no expiry date sink
    // to the bottom.
    list.sort((a, b) {
      if (a.expiresAt == null && b.expiresAt == null) return 0;
      if (a.expiresAt == null) return 1;
      if (b.expiresAt == null) return -1;
      return a.expiresAt!.compareTo(b.expiresAt!);
    });

    return list;
  }

  // ── Counts for the toggle row (respects search + month filter, not status) ──
  Map<StatusFilter, int> get _statusCounts {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final query = search.text.trim().toLowerCase();

    var base = _clients.where((c) {
      if (query.isNotEmpty) {
        final haystack = '${c.name} ${c.registration} ${c.vehicleName}'
            .toLowerCase();
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

  InputDecoration _fieldDecoration({String? hint, IconData? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13.5),
      suffixIcon: suffix != null
          ? Icon(suffix, color: Colors.black38, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(width: 1.4, color: Color(0xFF6366F1)),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget custominputformfield(
    String? example,
    IconData? icn,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: _fieldDecoration(hint: example, suffix: icn),
        ),
      ],
    );
  }

  // ── Status toggle row (All / Expired / 40 Days) ──
  Widget toggleswitch(
    String label,
    StatusFilter value,
    Color accent,
    int count,
  ) {
    final isSelected = _statusFilter == value;
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
          '$label($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            letterSpacing: 0.4,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> showdeleteconfirmation(_ClientRecord client) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Confirm delete',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'THIS WILL REMOVE THE CLIENT',
                style: GoogleFonts.poppins(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 0.5),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await SupabaseService.deletePolicy(client.id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      getData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Customer deleted successfully')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Delete failed: $e')),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  label: Text(
                    'Delete Customer',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFDC2626,
                    ).withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        width: 0.5,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget-function helpers used by clientcard (kept as plain methods,
  //    not separate reusable classes) ─────────────────────────────────────

  // Pulsing status dot — reuses the shared _pulseController from this State,
  // exactly like the blood-emergency card's AnimatedBuilder does. Sits still
  // (no glow) for calm statuses, pulses with a glow for urgent ones.
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

  // Pill-shaped status badge, styled like the blood card's BadgeWidget.
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

  // Flat rounded card shell (DashboardCard look) wrapping the row content.
  // Flat rounded card shell (DashboardCard look) wrapping the row content.
  // Border now blinks in sync with the status dot for urgent statuses.
  // Flat rounded card shell (DashboardCard look) wrapping the row content.
  // Border blinks in sync with the status dot for urgent statuses.
  Widget _clientCardShell({
    required Widget child,
    required VoidCallback onTap,
    required Color status,
    required bool urgent,
  }) {
    final dark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _pulseController,
      // `child` is built ONCE and reused every tick — only the decoration
      // is recomputed, not the whole subtree. This is what fixes the freeze.
      child: child,
      builder: (context, cardChild) {
        final t = urgent ? _pulseController.value : 0.0;
        final borderAlpha = urgent ? (30 + t * 190).round() : 20;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: status.withAlpha(borderAlpha), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.09),
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
                child: cardChild, // reused static child
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Client card (redesigned in the "blood emergency" dashboard-card style) ──
  Widget clientcard(_ClientRecord client) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final status = _classify(client.expiresAt, today);
    final statusColor = _statusColor(status);
    final borderColor = _borderColor(status);
    final statusText = _statusText(status, client.expiresAt, today);
    final initial = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';
    final isUrgent =
        status == ExpiryStatus.expired || status == ExpiryStatus.expiringSoon;

    return _clientCardShell(
      status: statusColor,
      urgent: isUrgent,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InsuranceDetailView(docid: client.id),
          ),
        );
        if (mounted) getData();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 8),
          // ── Pulsing status dot ──
          _statusDot(statusColor, isUrgent),
          const SizedBox(width: 18),

          // ── Vehicle + registration + type ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.vehicleName.isEmpty ? '—' : client.vehicleName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                Text(
                  '${client.registration} • ${client.type}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                _statusBadge(statusText, statusColor),
              ],
            ),
          ),

          // ── Avatar (trailing) + right-extreme status strip ──
          // IntrinsicHeight gives this Row a real, bounded height so the
          // strip's double.infinity can resolve instead of crashing layout.
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
              SizedBox(height: 8),
              SizedBox(
                height: 20,
                child: Text(
                  client.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Start-month filter picker ───────────────────────────
  Future<void> _pickStartMonth() async {
    int selectedYear = _startMonthFilter?.year ?? DateTime.now().year;
    int selectedMonth = _startMonthFilter?.month ?? DateTime.now().month;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by start month',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shows policies whose start date falls in this month',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedMonth,
                            decoration: _fieldDecoration(hint: 'Month'),
                            items: List.generate(12, (i) => i + 1)
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(_monthNames[m - 1]),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setDialogState(
                              () => selectedMonth = v ?? selectedMonth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedYear,
                            decoration: _fieldDecoration(hint: 'Year'),
                            items:
                                List.generate(
                                      6,
                                      (i) => DateTime.now().year - 4 + i,
                                    )
                                    .map(
                                      (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text('$y'),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setDialogState(
                              () => selectedYear = v ?? selectedYear,
                            ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    width: 0.5,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Clear',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ),
                          ),
                        if (_startMonthFilter != null)
                          const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(
                                () => _startMonthFilter = DateTime(
                                  selectedYear,
                                  selectedMonth,
                                ),
                              );
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Apply',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
    final indexes = _visibleClients;
    final monthLabel = _startMonthFilter == null
        ? 'This Month'
        : '${_monthNames[_startMonthFilter!.month - 1]} ${_startMonthFilter!.year}';

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 251, 251, 251),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              '$total_data_entry clients registered',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _pickStartMonth,
            label: Text(
              monthLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            icon: const Icon(
              Icons.calendar_month,
              size: 18,
              color: Colors.black,
            ),
          ),
          if (_startMonthFilter != null)
            IconButton(
              tooltip: 'Clear month filter',
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
              onPressed: () => setState(() => _startMonthFilter = null),
            ),
          const SizedBox(width: 4),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getData,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  children: [
                    // ── Status filter row ──
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 0, 0).withAlpha(10),
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
                                  Colors.black,
                                  counts[StatusFilter.all]!,
                                ),
                              ),
                              Expanded(
                                child: toggleswitch(
                                  'Expired',
                                  StatusFilter.expired,
                                  const Color.fromARGB(255, 245, 3, 3),
                                  counts[StatusFilter.expired]!,
                                ),
                              ),
                              Expanded(
                                child: toggleswitch(
                                  '40 Days',
                                  StatusFilter.expiringSoon,
                                  const Color.fromARGB(255, 255, 124, 2),
                                  counts[StatusFilter.expiringSoon]!,
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
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${indexes.length} shown',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.black,
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
                            const Icon(
                              Icons.inbox_outlined,
                              size: 36,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No clients match this filter',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: indexes.length,
                      itemBuilder: (context, index) =>
                          clientcard(indexes[index]),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
