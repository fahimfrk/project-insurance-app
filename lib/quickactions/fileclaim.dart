import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/services/supabase_service.dart';

class FileClaimScreen extends StatefulWidget {
  const FileClaimScreen({super.key});

  @override
  State<FileClaimScreen> createState() => _FileClaimScreenState();
}

class _FileClaimScreenState extends State<FileClaimScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Theme Colors (Dribbble Palette) ──────────────────────────────────────
  final Color bgDark = const Color(0xFF0D0E12); 
  final Color cardDark = const Color(0xFF1A1C23); 
  final Color limeGreen = const Color(0xFFB2F068); 
  final Color accentOrange = const Color(0xFFFF6B4A); 
  final Color badgePink = const Color(0xFFFF2E7E); 
  final Color chartCyan = const Color(0xFF00D1D1); 

  final _policyNumberCtrl = TextEditingController();
  String? _claimType;
  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _estimatedLossCtrl = TextEditingController();
  final _firNumberCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _preferredGarageCtrl = TextEditingController();
  bool _thirdPartyInvolved = false;
  bool _injuriesReported = false;

  bool _saving = false;

  final Map<String, bool> _documents = {
    'Photos of Damage': false,
    'RC Book Copy': false,
    'Driving License Copy': false,
    'Police FIR Copy': false,
    'Repair Estimate / Bill': false,
    'Original Policy Copy': false,
  };

  final List<String> _claimTypes = const [
    'Accident / Collision',
    'Theft',
    'Fire',
    'Natural Calamity',
    'Third Party Liability',
    'Medical / Health Claim',
    'Glass / Windshield Damage',
  ];

  @override
  void dispose() {
    _policyNumberCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _estimatedLossCtrl.dispose();
    _firNumberCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _preferredGarageCtrl.dispose();
    super.dispose();
  }

  bool get isDark => MediaQuery.of(context).platformBrightness == Brightness.dark;

  Future<void> _pickIncidentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark 
            ? ColorScheme.dark(primary: chartCyan, surface: cardDark)
            : ColorScheme.light(primary: chartCyan),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _pickIncidentTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark 
            ? ColorScheme.dark(primary: chartCyan, surface: cardDark)
            : ColorScheme.light(primary: chartCyan),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentTime = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_claimType == null) {
        _showSnack('Please select a claim type');
        return;
      }
      if (_incidentDate == null) {
        _showSnack('Please select the date of incident');
        return;
      }

      setState(() => _saving = true);

      final claimPayload = {
        'policy_number': _policyNumberCtrl.text.trim(),
        'claim_type': _claimType,
        'incident_date': _incidentDate!.toIso8601String(),
        'incident_time': _incidentTime?.format(context),
        'location': _locationCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'estimated_loss': _estimatedLossCtrl.text.trim(),
        'fir_number': _firNumberCtrl.text.trim(),
        'third_party_involved': _thirdPartyInvolved,
        'injuries_reported': _injuriesReported,
        'contact_phone': _contactPhoneCtrl.text.trim(),
        'preferred_garage': _preferredGarageCtrl.text.trim(),
        'documents': _documents.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
      };

      try {
        await SupabaseService.createClaim(claimPayload);
        if (!mounted) return;
        _showSuccess('Claim registered successfully.');
      } catch (e) {
        if (!mounted) return;
        _showSnack('Failed to register claim: $e');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showSuccess(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: limeGreen),
            const SizedBox(width: 10),
            Text(
              'Claim Filed!',
              style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: Text('Done', style: GoogleFonts.outfit(color: chartCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── STYLING HELPERS ───
  InputDecoration _decoration(String hint, IconData? icon) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : Colors.black.withOpacity(0.08);
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final iconColor = isDark ? Colors.white54 : Colors.black38;

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      filled: true,
      fillColor: bgColor,
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: hintColor, fontSize: 13.5),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: iconColor) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(borderColor),
      enabledBorder: border(borderColor, 1),
      focusedBorder: border(chartCyan, 1.5),
      errorBorder: border(badgePink, 1.2),
      focusedErrorBorder: border(badgePink, 1.5),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: accentOrange, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    final cColor = isDark ? cardDark : Colors.white;
    final bColor = isDark ? const Color(0xFF3A3A3A) : Colors.black.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bColor),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontSize: 14.5),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: _decoration(hint, icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgCol = isDark ? bgDark : const Color(0xFFF3F4F8);
    final cColor = isDark ? cardDark : Colors.white;
    final textMain = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cColor,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textMain),
        ),
        title: Text(
          'File a Claim',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textMain),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: accentOrange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For accidents involving injury or third-party damage, inform the police and keep the FIR copy handy.',
                      style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            
            _sectionHeader('Policy & Claim Type'),
            _card([
              _textField(_policyNumberCtrl, 'Policy Number', Icons.policy_outlined, required: true),
              DropdownButtonFormField<String>(
                value: _claimType,
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontSize: 14.5),
                decoration: _decoration('Select Claim Type', Icons.category_outlined),
                items: _claimTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _claimType = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ]),

            _sectionHeader('Incident Details'),
            _card([
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickIncidentDate,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: _decoration('Date', Icons.calendar_today_outlined),
                        child: Text(
                          _incidentDate == null ? 'Select' : '${_incidentDate!.day}/${_incidentDate!.month}/${_incidentDate!.year}',
                          style: GoogleFonts.outfit(color: _incidentDate == null ? (isDark ? Colors.white38 : Colors.black38) : textMain, fontSize: 14.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickIncidentTime,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: _decoration('Time', Icons.access_time_rounded),
                        child: Text(
                          _incidentTime == null ? 'Select' : _incidentTime!.format(context),
                          style: GoogleFonts.outfit(color: _incidentTime == null ? (isDark ? Colors.white38 : Colors.black38) : textMain, fontSize: 14.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _textField(_locationCtrl, 'Location of Incident', Icons.location_on_outlined, required: true),
              _textField(_descriptionCtrl, 'Describe What Happened', Icons.description_outlined, maxLines: 4, required: true),
              
              SwitchListTile(
                value: _thirdPartyInvolved,
                onChanged: (v) => setState(() => _thirdPartyInvolved = v),
                title: Text('Third-party involved?', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textMain)),
                activeColor: chartCyan,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _injuriesReported,
                onChanged: (v) => setState(() => _injuriesReported = v),
                title: Text('Any injuries reported?', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textMain)),
                activeColor: badgePink,
                contentPadding: EdgeInsets.zero,
              ),
              
              _textField(_firNumberCtrl, 'Police FIR Number (if applicable)', Icons.local_police_outlined, required: false),
            ]),

            _sectionHeader('Loss Estimate'),
            _card([
              _textField(_estimatedLossCtrl, 'Estimated Loss Amount ₹', Icons.currency_rupee_outlined, keyboardType: TextInputType.number, required: true),
              _textField(_preferredGarageCtrl, 'Preferred Garage / Hospital (optional)', Icons.local_hospital_outlined, required: false),
            ]),

            _sectionHeader('Supporting Documents'),
            _card([
              for (final key in _documents.keys)
                CheckboxListTile(
                  value: _documents[key],
                  onChanged: (v) => setState(() => _documents[key] = v ?? false),
                  title: Text(key, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: textMain)),
                  activeColor: chartCyan,
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSnack('File picker coming soon'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: chartCyan.withOpacity(0.5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(Icons.upload_file, color: chartCyan, size: 20),
                  label: Text('Upload Documents', style: GoogleFonts.outfit(color: chartCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ]),

            _sectionHeader('Contact'),
            _card([
              _textField(_contactPhoneCtrl, 'Contact Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone, required: true),
            ]),
            
            const SizedBox(height: 32),
            
            // Premium Submit Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                color: accentOrange,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: accentOrange.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _saving ? null : _submit,
                  child: Center(
                    child: _saving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Submit Claim', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}