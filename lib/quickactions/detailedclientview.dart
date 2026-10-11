import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insurance/quickactions/add_customer.dart';
import 'package:insurance/services/supabase_service.dart';

class InsuranceDetailView extends StatefulWidget {
  final String docid;

  const InsuranceDetailView({super.key, required this.docid});

  @override
  State<InsuranceDetailView> createState() => _InsuranceDetailViewState();
}

class _InsuranceDetailViewState extends State<InsuranceDetailView> {
  String brand = '';
  String model = '';
  String year = '';
  String registration = '';
  String startdate = '';
  String enddate = '';
  String customername = '';
  String careoff = '';
  String phone = '';
  String Insuranceprovider = '';
  String providercode = '';
  String policytype = '';
  String expensecategory = '';
  String note = '';
  DateTime? startAt;
  DateTime? expiresAt;
  DateTime? uploadedAt;

  bool loading = true;
  bool notFound = false;

  static const Color primaryGreen = Color(0xFF34D399); // Mint green
  static const Color dangerRed = Color(0xFFEF4444);
  static const int expiringSoonDays = 40;

  static const List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final policy = await SupabaseService.getPolicyById(widget.docid);
      if (!mounted) return;
      if (policy == null) {
        setState(() {
          loading = false;
          notFound = true;
        });
        return;
      }

      setState(() {
        brand = policy.brand;
        model = policy.model;
        year = policy.year;
        registration = policy.registration;
        customername = policy.customerName;
        careoff = policy.careOf;
        phone = policy.phone;
        Insuranceprovider = policy.insuranceProvider;
        providercode = policy.providerCode;
        policytype = policy.policyType;
        expensecategory = 'Vehicle Insurance';
        note = policy.vehicleNote.isNotEmpty ? policy.vehicleNote : policy.note;
        startAt = policy.startDate;
        expiresAt = policy.expiresAt;
        uploadedAt = policy.createdAt ?? DateTime.now();
        startdate = policy.startDateString.isNotEmpty
            ? policy.startDateString
            : (policy.startDate != null ? _fmtSlash(policy.startDate!) : '');
        enddate = policy.expiresAtString.isNotEmpty
            ? policy.expiresAtString
            : (policy.expiresAt != null ? _fmtSlash(policy.expiresAt!) : '');
        loading = false;
        notFound = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        notFound = true;
      });
      _snack('Error loading policy: $e');
    }
  }

  Future<void> _confirmDelete(bool isDark) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: dangerRed),
            const SizedBox(width: 10),
            Text('Delete customer?', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        content: Text(
          'This will permanently remove '
          '${customername.isNotEmpty ? customername : 'this customer'}'
          '${registration.isNotEmpty ? ' ($registration)' : ''}. '
          'This can\'t be undone.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: dangerRed),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await SupabaseService.deletePolicy(widget.docid);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack('Failed to delete: $e');
    }
  }

  Future<void> _openRenewalSheet(bool isDark) async {
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RenewalSheet(
        docid: widget.docid,
        initialProvider: Insuranceprovider,
        initialProviderCode: providercode,
        initialNote: note,
        initialStart: startAt,
        initialEnd: expiresAt,
        isDark: isDark,
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        Insuranceprovider = updated['insuranceprovider'] as String;
        providercode = updated['code'] as String;
        note = updated['note'] as String;
        startAt = updated['startAt'] as DateTime;
        expiresAt = updated['expiresAt'] as DateTime;
        startdate = updated['startAtstring'] as String;
        enddate = updated['expiresAtstring'] as String;
      });
      _snack('Policy renewed successfully');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('$what copied');
  }

  bool _blank(String v) => v.trim().isEmpty || v == 'Not added yet';
  String _fmtSlash(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtDateTime(DateTime d) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${_months[d.month - 1]} ${d.year}, $h12:$mm $ampm';
  }
  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int? get _daysLeft {
    final e = expiresAt;
    if (e == null) return null;
    return _dayOnly(e).difference(_dayOnly(DateTime.now())).inDays;
  }

  Color get _statusColor {
    final d = _daysLeft;
    if (d == null) return primaryGreen;
    if (d < 0) return dangerRed;
    if (d <= expiringSoonDays) return const Color.fromARGB(255, 245, 158, 11);
    return primaryGreen;
  }

  String get _statusLabel {
    final d = _daysLeft;
    if (d == null) return '';
    if (d < 0) return 'EXPIRED';
    if (d <= expiringSoonDays) return 'EXPIRING SOON';
    return 'ACTIVE';
  }

  IconData get _statusIcon {
    final d = _daysLeft;
    if (d == null) return Icons.shield_rounded;
    if (d < 0) return Icons.gpp_bad_rounded;
    if (d <= expiringSoonDays) return Icons.hourglass_bottom_rounded;
    return Icons.verified_user_rounded;
  }

  String get _statusText {
    final d = _daysLeft;
    if (d == null) return 'Validity period';
    if (d == 0) return 'Expires today';
    if (d < 0) return 'Expired ${-d} ${-d == 1 ? 'day' : 'days'} ago';
    return '$d ${d == 1 ? 'day' : 'days'} remaining';
  }

  int get _totalDays {
    if (startAt == null || expiresAt == null) return 0;
    return _dayOnly(expiresAt!).difference(_dayOnly(startAt!)).inDays;
  }

  int get _usedDays {
    if (startAt == null) return 0;
    final used = _dayOnly(DateTime.now()).difference(_dayOnly(startAt!)).inDays;
    return used.clamp(0, _totalDays);
  }

  double get _elapsedFraction {
    if (_totalDays <= 0) return startAt != null && expiresAt != null ? 1 : 0;
    return (_usedDays / _totalDays).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1714) : const Color(0xFFF6FBF8);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
        ),
        title: Text(
          'Policy Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Edit',
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => addcustomer(mode: 1, docid: widget.docid)));
                if (mounted) _loadData();
              },
              style: IconButton.styleFrom(backgroundColor: primaryGreen.withOpacity(0.10)),
              icon: const Icon(Icons.edit_outlined, size: 20, color: primaryGreen),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (loading || notFound) ? null : _bottomActionBar(isDark, cardColor),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: primaryGreen))
            : notFound
            ? _emptyState(isDark)
            : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _reveal(0, _heroCard()),
                      const SizedBox(height: 18),
                      _reveal(1, _validityCard(isDark, cardColor)),
                      const SizedBox(height: 26),
                      _reveal(2, Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(Icons.person_outline_rounded, 'Customer Information', isDark),
                          const SizedBox(height: 10),
                          _customerCard(isDark, cardColor),
                        ],
                      )),
                      const SizedBox(height: 26),
                      _reveal(3, Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(Icons.shield_outlined, 'Insurance Information', isDark),
                          const SizedBox(height: 10),
                          _policyCard(isDark, cardColor),
                        ],
                      )),
                      if (!_blank(note)) ...[
                        const SizedBox(height: 26),
                        _reveal(4, Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(Icons.notes_rounded, 'Note', isDark),
                            const SizedBox(height: 10),
                            _card(
                              isDark: isDark, cardColor: cardColor,
                              children: [
                                Text(note, style: TextStyle(fontSize: 13.5, color: textColor, height: 1.4)),
                              ],
                            ),
                          ],
                        )),
                      ],
                      if (uploadedAt != null) ...[
                        const SizedBox(height: 18),
                        _reveal(5, Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 6),
                              Text('Added on ${_fmtDateTime(uploadedAt!)}', style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _bottomActionBar(bool isDark, Color cardColor) {
    return Material(
      color: cardColor,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(flex: 3, child: _renewelbuttonButton(isDark)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _deleteButton(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reveal(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c)),
      child: child,
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded, size: 38, color: primaryGreen),
            ),
            const SizedBox(height: 16),
            Text('Record not found', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 6),
            Text('This customer may have been deleted.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(26)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(right: -22, bottom: -18, child: Icon(Icons.directions_car_filled_rounded, size: 170, color: Colors.white.withOpacity(0.09))),
            Positioned(top: -50, left: -40, child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: _glassChip(Icons.business_outlined, _blank(Insuranceprovider) ? 'Insurance' : Insuranceprovider)),
                      const SizedBox(width: 8),
                      if (!_blank(policytype)) _glassChip(null, policytype),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(brand.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.75))),
                  const SizedBox(height: 2),
                  Text(model, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _plate(),
                      const Spacer(),
                      if (!_blank(year)) _glassChip(Icons.calendar_today_rounded, year),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassChip(IconData? icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.18))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: Colors.white), const SizedBox(width: 6)],
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _plate() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: registration.isEmpty ? null : () => _copy(registration, 'Registration number'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.black87, width: 1.4)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(registration.isEmpty ? '—' : registration, style: const TextStyle(fontSize: 15.5, letterSpacing: 2, fontWeight: FontWeight.w800, color: Colors.black87)),
              if (registration.isNotEmpty) ...[const SizedBox(width: 10), const Icon(Icons.copy_rounded, size: 14, color: Colors.black38)],
            ],
          ),
        ),
      ),
    );
  }

  Widget _validityCard(bool isDark, Color cardColor) {
    final color = _statusColor;
    final hasDates = startAt != null && expiresAt != null;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : color.withOpacity(0.18);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.10), shape: BoxShape.circle), child: Icon(_statusIcon, color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Policy Validity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 3),
                    Text(_statusText, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (_statusLabel.isNotEmpty)
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)), child: Text(_statusLabel, style: TextStyle(color: color, fontSize: 10.5, letterSpacing: 0.4, fontWeight: FontWeight.w800))),
            ],
          ),
          if (hasDates) ...[
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _elapsedFraction),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation<Color>(color)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_usedDays of $_totalDays days used', style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500)),
                Text('${(_elapsedFraction * 100).round()}%', style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _dateBox(icon: Icons.play_circle_outline_rounded, title: 'START DATE', date: startdate, isDark: isDark)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black26)),
              Expanded(child: _dateBox(icon: Icons.event_available_rounded, title: 'EXPIRY DATE', date: enddate, highlighted: true, accent: color, isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customerCard(bool isDark, Color cardColor) {
    final initial = customername.trim().isEmpty ? '?' : customername.trim()[0].toUpperCase();
    return _card(
      isDark: isDark, cardColor: cardColor,
      children: [
        Row(
          children: [
            Container(
              width: 52, height: 52, alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryGreen, Color(0xFF059669)])),
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Name', style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(customername.isEmpty ? '—' : customername, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          ],
        ),
        _divider(isDark),
        _detailRow(icon: Icons.family_restroom_rounded, title: 'C/O (Care of)', value: careoff, isDark: isDark),
        _divider(isDark),
        _detailRow(icon: Icons.phone_outlined, title: 'Phone Number', value: phone, trailing: _blank(phone) ? null : _copyButton(phone, 'Phone number', isDark), isDark: isDark),
      ],
    );
  }

  Widget _policyCard(bool isDark, Color cardColor) {
    return _card(
      isDark: isDark, cardColor: cardColor,
      children: [
        _detailRow(icon: Icons.business_outlined, title: 'Insurance Provider', value: Insuranceprovider, isDark: isDark),
        _divider(isDark),
        _detailRow(icon: Icons.tag_rounded, title: 'Provider Code', value: providercode, trailing: _blank(providercode) ? null : _copyButton(providercode, 'Provider code', isDark), isDark: isDark),
        _divider(isDark),
        Row(
          children: [
            _iconBox(Icons.policy_outlined, isDark),
            const SizedBox(width: 12),
            Expanded(child: Text('Policy Type', style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.10), borderRadius: BorderRadius.circular(30)),
              child: Text(_blank(policytype) ? '—' : policytype, style: const TextStyle(color: primaryGreen, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        _divider(isDark),
        _detailRow(icon: Icons.category_outlined, title: 'Expense Category', value: expensecategory, isDark: isDark),
      ],
    );
  }

  Widget _renewelbuttonButton(bool isDark) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: () => _openRenewalSheet(isDark),
        icon: Icon(Icons.autorenew_rounded, size: 20, color: isDark ? Colors.black : Colors.white),
        label: Text('Renew Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.black : Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      ),
    );
  }

  Widget _deleteButton(bool isDark) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDelete(isDark),
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        label: const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: dangerRed,
          backgroundColor: dangerRed.withOpacity(0.04),
          side: BorderSide(color: dangerRed.withOpacity(0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _copyButton(String text, String what, bool isDark) {
    return IconButton(tooltip: 'Copy', onPressed: () => _copy(text, what), visualDensity: VisualDensity.compact, icon: Icon(Icons.copy_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black38));
  }

  Widget _sectionTitle(IconData icon, String title, bool isDark) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: primaryGreen.withOpacity(0.10), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: primaryGreen)),
        const SizedBox(width: 9),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  Widget _card({required List<Widget> children, required bool isDark, required Color cardColor}) {
    final borderColor = isDark ? const Color(0xFF3A3A3A) : Colors.black.withOpacity(0.05);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.035), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  Widget _detailRow({required IconData icon, required String title, required String value, bool bold = false, Widget? trailing, required bool isDark}) {
    final blank = value.trim().isEmpty || value == 'Not added yet';
    return Row(
      children: [
        _iconBox(icon, isDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(blank ? 'Not added' : value, style: TextStyle(fontSize: 14, color: blank ? (isDark ? Colors.white24 : Colors.black26) : (isDark ? Colors.white : Colors.black87), fontStyle: blank ? FontStyle.italic : FontStyle.normal, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _iconBox(IconData icon, bool isDark) {
    return Container(width: 40, height: 40, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F3), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: primaryGreen, size: 19));
  }

  Widget _dateBox({required IconData icon, required String title, required String date, bool highlighted = false, Color accent = primaryGreen, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: highlighted ? accent.withOpacity(0.07) : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F8F9)), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: highlighted ? accent : (isDark ? Colors.white54 : Colors.black45)),
              const SizedBox(width: 5),
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: highlighted ? accent : (isDark ? Colors.white54 : Colors.black45)))),
            ],
          ),
          const SizedBox(height: 8),
          Text(date.isEmpty ? '—' : date, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, thickness: 0.7, color: isDark ? const Color(0xFF3A3A3A) : Colors.black.withOpacity(0.06)));
  }
}

class _RenewalSheet extends StatefulWidget {
  final String docid;
  final String initialProvider;
  final String initialProviderCode;
  final String initialNote;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final bool isDark;

  const _RenewalSheet({
    required this.docid,
    required this.initialProvider,
    required this.initialProviderCode,
    required this.initialNote,
    required this.initialStart,
    required this.initialEnd,
    required this.isDark,
  });

  @override
  State<_RenewalSheet> createState() => _RenewalSheetState();
}

class _RenewalSheetState extends State<_RenewalSheet> {
  static const Color _green = Color(0xFF34D399);
  static const double _radius = 14;
  static const String _other = 'Other';
  static const List<String> _providers = ['New India Insurance', 'National Insurance', 'IFFCO Tokio General Insurance', 'Oriental Insurance'];

  late final TextEditingController _codeCtrl;
  late final TextEditingController _customProviderCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;

  String? _provider;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialProviderCode);
    _noteCtrl = TextEditingController(text: widget.initialNote);

    final knownProvider = widget.initialProvider.trim();
    if (_providers.contains(knownProvider)) {
      _provider = knownProvider;
      _customProviderCtrl = TextEditingController();
    } else if (knownProvider.isNotEmpty) {
      _provider = _other;
      _customProviderCtrl = TextEditingController(text: knownProvider);
    } else {
      _customProviderCtrl = TextEditingController();
    }

    _startDate = widget.initialEnd ?? widget.initialStart ?? DateTime.now();
    _endDate = _startDate != null ? DateTime(_startDate!.year + 1, _startDate!.month, _startDate!.day) : null;

    _startCtrl = TextEditingController(text: _startDate != null ? _fmt(_startDate!) : '');
    _endCtrl = TextEditingController(text: _endDate != null ? _fmt(_endDate!) : '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose(); _customProviderCtrl.dispose(); _noteCtrl.dispose(); _startCtrl.dispose(); _endCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String get _providerName => _provider == _other ? _customProviderCtrl.text.trim() : (_provider ?? '');
  bool get _canSave => _provider != null && (_provider != _other || _customProviderCtrl.text.trim().isNotEmpty) && _startDate != null && _endDate != null && !_endDate!.isBefore(_startDate!) && !_saving;

  Future<void> _pickDate({required bool isStart}) async {
    FocusScope.of(context).unfocus();
    final init = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    final first = isStart ? DateTime(2000) : (_startDate ?? DateTime(2000));

    final picked = await showDatePicker(
      context: context,
      initialDate: init.isBefore(first) ? first : init,
      firstDate: first,
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: widget.isDark ? const ColorScheme.dark(primary: _green, surface: Color(0xFF1E1E1E)) : const ColorScheme.light(primary: Color(0xFF059669)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked; _startCtrl.text = _fmt(picked);
        if (_endDate != null && _endDate!.isBefore(picked)) { _endDate = null; _endCtrl.clear(); }
      } else {
        _endDate = picked; _endCtrl.text = _fmt(picked);
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'insuranceprovider': _providerName, 'code': _codeCtrl.text.trim(), 'note': _noteCtrl.text.trim(),
      'startAt': _startDate!, 'expiresAt': _endDate!, 'startAtstring': _startCtrl.text.trim(), 'expiresAtstring': _endCtrl.text.trim(),
    };

    try {
      await SupabaseService.renewPolicy(
        policyId: widget.docid,
        renewalDetails: { 'policy_number': widget.docid, 'ncb_applied': '25%', 'new_idv': '', 'coverage_type': 'Comprehensive', 'total_premium': 0, 'renewal_start_date': _startDate!.toIso8601String(), 'payment_mode': 'UPI'},
        newStartDate: _startDate, newExpiryDate: _endDate, newProvider: _providerName, newProviderCode: _codeCtrl.text.trim(), newNote: _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, data);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renewal failed: $e')));
      }
    }
  }

  InputDecoration _decoration({String? hint, IconData? icon}) {
    final cardColor = widget.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFAFBFC);
    final borderColor = widget.isDark ? const Color(0xFF3A3A3A) : Colors.black.withOpacity(0.08);
    final textColor = widget.isDark ? Colors.white54 : Colors.black38;

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      filled: true, fillColor: cardColor, hintText: hint, hintStyle: TextStyle(color: textColor, fontSize: 13.5),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: textColor) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(borderColor), enabledBorder: border(borderColor), focusedBorder: border(_green, 1.4),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : Colors.black87)));

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final activeColor = widget.isDark ? _green : const Color(0xFF059669);
    final inactiveBg = widget.isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final inactiveBorder = widget.isDark ? const Color(0xFF3A3A3A) : Colors.black.withOpacity(0.1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(color: selected ? activeColor : inactiveBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? activeColor : inactiveBorder)),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12), onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? (widget.isDark ? Colors.black : Colors.white) : (widget.isDark ? Colors.white54 : Colors.black54))),
          ),
        ),
      ),
    );
  }

  Widget _dateTile({required String label, required TextEditingController controller, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(controller: controller, readOnly: true, onTap: onTap, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.isDark ? Colors.white : Colors.black), decoration: _decoration(hint: 'dd/mm/yyyy').copyWith(suffixIcon: const Icon(Icons.calendar_month_outlined))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bgColor = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(color: bgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: widget.isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(4)))),
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.autorenew_rounded, color: _green, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Renew Policy', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: textColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Customer and vehicle details stay unchanged. Only the fields below are updated.', style: TextStyle(fontSize: 12.5, color: widget.isDark ? Colors.white54 : Colors.black54)),
                const SizedBox(height: 20),

                _label('Insurance provider'),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final p in [..._providers, _other]) _chip(p, _provider == p, () => setState(() => _provider = p))]),
                if (_provider == _other) ...[
                  const SizedBox(height: 14), _label('Company name'),
                  TextFormField(controller: _customProviderCtrl, onChanged: (_) => setState(() {}), style: TextStyle(color: textColor), decoration: _decoration(hint: 'Enter insurance company name', icon: Icons.business_outlined)),
                ],
                const SizedBox(height: 16),

                _label('Provider code'),
                TextFormField(controller: _codeCtrl, onChanged: (_) => setState(() {}), style: TextStyle(color: textColor), decoration: _decoration(hint: 'e.g. Rayid', icon: Icons.tag_rounded)),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _dateTile(label: 'New start date', controller: _startCtrl, onTap: () => _pickDate(isStart: true))),
                    const SizedBox(width: 12),
                    Expanded(child: _dateTile(label: 'New expiry date', controller: _endCtrl, onTap: () => _pickDate(isStart: false))),
                  ],
                ),
                const SizedBox(height: 16),

                _label('Note'),
                TextFormField(controller: _noteCtrl, onChanged: (_) => setState(() {}), maxLines: 3, style: TextStyle(color: textColor), decoration: _decoration(hint: 'e.g, Write a note')),
                const SizedBox(height: 22),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      foregroundColor: widget.isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
                    ),
                    child: _saving ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: widget.isDark ? Colors.black : Colors.white)) : const Text('Confirm Renewal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}