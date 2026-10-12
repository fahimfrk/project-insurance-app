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

class _SalesState extends State<Sales> {
  TextEditingController search = TextEditingController();

  List<_ClientRecord> _clients = [];
  bool _loading = true;
  int total_data_entry = 0;

  StatusFilter _statusFilter = StatusFilter.all;
  DateTime? _startMonthFilter; 

  // Dribbble Color Palette
  final Color bgDark = const Color(0xFF0D0E12); 
  final Color limeGreen = const Color(0xFFB2F068); 
  final Color accentOrange = const Color(0xFFFF6B4A); 
  final Color badgePink = const Color(0xFFFF2E7E); 
  final Color badgeBlue = const Color(0xFF3B82F6); 
  final Color chartCyan = const Color(0xFF00D1D1); 

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    getData();
  }

  @override
  void dispose() {
    search.dispose();
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

  Widget toggleswitch(String label, StatusFilter value, int count, bool isDark) {
    final isSelected = _statusFilter == value;
    
    // Use the neon colors for the selected tab to match the Dribbble design
    Color activeColor = Colors.white;
    if (value == StatusFilter.expired) activeColor = badgePink;
    if (value == StatusFilter.expiringSoon) activeColor = accentOrange;
    if (value == StatusFilter.all && isDark) activeColor = Colors.white24;
    if (value == StatusFilter.all && !isDark) activeColor = Colors.black12;

    final textColor = isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54);
    
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? activeColor : Colors.transparent,
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 12,
            letterSpacing: 0.2,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected && value != StatusFilter.all ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  // ─── DRIBBBLE STYLE CARD (Matches Dashboard Perfectly) ───
  Widget clientcard(_ClientRecord client, bool isDark, Color cardCol) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final status = _classify(client.expiresAt, today);
    
    bool isUrgent = status == ExpiryStatus.expired;
    bool isUpcoming = status == ExpiryStatus.expiringSoon;

    Color badgeColor = isUrgent ? badgePink : (isUpcoming ? accentOrange : limeGreen);
    String badgeText = isUrgent ? 'High' : (isUpcoming ? 'Med' : 'Low');

    Color textMain = isDark ? Colors.white : Colors.black87;
    Color textSub = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: () {
        if (!client.id.startsWith('fake_')) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => InsuranceDetailView(docid: client.id))).then((_) => getData());
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is a demo record.')));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardCol, 
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(badgeText, style: GoogleFonts.outfit(color: isUrgent ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: badgeBlue, size: 8),
                    const SizedBox(width: 4),
                    Text(client.type, style: GoogleFonts.outfit(color: textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 14),
            Text(client.name, style: GoogleFonts.outfit(color: textMain, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_car_rounded, color: textSub, size: 14),
                const SizedBox(width: 6),
                Text('${client.vehicleName} · ${client.registration}', style: GoogleFonts.outfit(color: textSub, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_statusText(status, client.expiresAt, today), style: GoogleFonts.outfit(color: textSub, fontSize: 12)),
                SizedBox(
                  width: 50,
                  height: 24,
                  child: Stack(
                    children: [
                      Positioned(right: 0, child: CircleAvatar(radius: 12, backgroundColor: badgeBlue, child: Text('A', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white)))),
                      Positioned(right: 12, child: CircleAvatar(radius: 12, backgroundColor: badgePink, child: Text('B', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white)))),
                      Positioned(right: 24, child: CircleAvatar(radius: 12, backgroundColor: chartCyan, child: Text('C', style: GoogleFonts.outfit(fontSize: 10, color: Colors.black)))),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgCol = isDark ? bgDark : const Color(0xFFF3F4F8);
    final cardCol = isDark ? const Color(0xFF1A1C23) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF6B7280);

    final indexes = _visibleClients;
    final monthLabel = _startMonthFilter == null ? 'This Month' : '${_monthNames[_startMonthFilter!.month - 1]} ${_startMonthFilter!.year}';

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Customers', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            Text('$total_data_entry clients registered', style: GoogleFonts.outfit(fontSize: 12, color: subTextColor)),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getData,
          color: accentOrange,
          backgroundColor: cardCol,
          child: _loading
              ? Center(child: CircularProgressIndicator(color: accentOrange))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  children: [
                    // ── Search Bar ──
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: cardCol,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: search,
                        style: GoogleFonts.outfit(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search_rounded, color: subTextColor, size: 20),
                          hintText: 'Search clients, vehicles...',
                          hintStyle: GoogleFonts.outfit(color: subTextColor, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── IOS Segmented Filter ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardCol,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: toggleswitch('All', StatusFilter.all, _statusCounts[StatusFilter.all]!, isDark)),
                          Expanded(child: toggleswitch('High', StatusFilter.expired, _statusCounts[StatusFilter.expired]!, isDark)),
                          Expanded(child: toggleswitch('Med', StatusFilter.expiringSoon, _statusCounts[StatusFilter.expiringSoon]!, isDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Client List', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        Text('${indexes.length} shown', style: GoogleFonts.outfit(fontSize: 12, color: subTextColor)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (indexes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 12),
                            Text('No clients match this filter', style: GoogleFonts.outfit(fontSize: 14, color: subTextColor)),
                          ],
                        ),
                      ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: indexes.length,
                      itemBuilder: (context, index) => clientcard(indexes[index], isDark, cardCol),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}