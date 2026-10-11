import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/services/supabase_service.dart';

/// ---------------------------------------------------------------------
/// FILE CLAIM SCREEN
/// ---------------------------------------------------------------------
/// Captures everything needed to register an insurance claim: the
/// policy it relates to, incident specifics, estimated loss, supporting
/// documents, and the contact point for claim follow-up.
/// ---------------------------------------------------------------------
class FileClaimScreen extends StatefulWidget {
  const FileClaimScreen({super.key});

  @override
  State<FileClaimScreen> createState() => _FileClaimScreenState();
}

class _FileClaimScreenState extends State<FileClaimScreen> {
  final _formKey = GlobalKey<FormState>();

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

  // Document checklist (represents attachments the user has prepared)
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

  Future<void> _pickIncidentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _pickIncidentTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
        _showSnack('Claim registered successfully in Supabase');
        Navigator.of(context).maybePop(claimPayload);
      } catch (e) {
        if (!mounted) return;
        _showSnack('Failed to register claim: $e');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1714) : const Color(0xFFF6FBF8);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final accent = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    final warnColor = const Color(0xFFF59E0B);
    final borderColor = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        title: Text(
          'File a Claim',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: warnColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: warnColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: warnColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For accidents involving injury or third-party damage, '
                      'inform the police and keep the FIR copy handy.',
                      style: TextStyle(fontSize: 11.5, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
            _sectionHeader('Policy & Claim Type', accent, textColor),
            _card(cardColor, borderColor, [
              _textField(
                _policyNumberCtrl,
                'Policy Number',
                Icons.policy_outlined,
                textColor,
                borderColor,
                required: true,
              ),
              _dropdownField(
                label: 'Claim Type',
                value: _claimType,
                items: _claimTypes,
                onChanged: (v) => setState(() => _claimType = v),
                textColor: textColor,
                borderColor: borderColor,
              ),
            ]),
            _sectionHeader('Incident Details', accent, textColor),
            _card(cardColor, borderColor, [
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      label: 'Date of Incident',
                      value: _incidentDate,
                      onTap: _pickIncidentDate,
                      textColor: textColor,
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickIncidentTime,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Time',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          suffixIcon: const Icon(Icons.access_time, size: 18),
                        ),
                        child: Text(
                          _incidentTime == null
                              ? 'Select'
                              : _incidentTime!.format(context),
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _textField(
                _locationCtrl,
                'Location of Incident',
                Icons.location_on_outlined,
                textColor,
                borderColor,
                required: true,
              ),
              _textField(
                _descriptionCtrl,
                'Describe What Happened',
                Icons.description_outlined,
                textColor,
                borderColor,
                maxLines: 4,
                required: true,
              ),
              SwitchListTile(
                value: _thirdPartyInvolved,
                onChanged: (v) => setState(() => _thirdPartyInvolved = v),
                title: Text(
                  'Third-party vehicle/property involved?',
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
                activeThumbColor: accent,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: _injuriesReported,
                onChanged: (v) => setState(() => _injuriesReported = v),
                title: Text(
                  'Any injuries reported?',
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
                activeThumbColor: accent,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              _textField(
                _firNumberCtrl,
                'Police FIR Number (if applicable)',
                Icons.local_police_outlined,
                textColor,
                borderColor,
                required: false,
              ),
            ]),
            _sectionHeader('Loss Estimate', accent, textColor),
            _card(cardColor, borderColor, [
              _textField(
                _estimatedLossCtrl,
                'Estimated Loss / Damage Amount ₹',
                Icons.currency_rupee_outlined,
                textColor,
                borderColor,
                keyboardType: TextInputType.number,
                required: true,
              ),
              _textField(
                _preferredGarageCtrl,
                'Preferred Garage / Hospital (optional)',
                Icons.local_hospital_outlined,
                textColor,
                borderColor,
                required: false,
              ),
            ]),
            _sectionHeader('Supporting Documents', accent, textColor),
            _card(cardColor, borderColor, [
              for (final key in _documents.keys)
                CheckboxListTile(
                  value: _documents[key],
                  onChanged: (v) =>
                      setState(() => _documents[key] = v ?? false),
                  title: Text(
                    key,
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  secondary: Icon(Icons.attach_file, size: 18, color: accent),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: accent,
                  dense: true,
                ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: hook into file/image picker
                  _showSnack('Attach files via device picker');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.upload_file, color: accent, size: 18),
                label: Text(
                  'Upload Documents',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            _sectionHeader('Contact for Follow-up', accent, textColor),
            _card(cardColor, borderColor, [
              _textField(
                _contactPhoneCtrl,
                'Contact Phone Number',
                Icons.phone_outlined,
                textColor,
                borderColor,
                keyboardType: TextInputType.phone,
                required: true,
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  'Submit Claim',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Reusable building blocks ----------------------------------------

  Widget _sectionHeader(String label, Color accent, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, left: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Color cardColor, Color borderColor, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    Color textColor,
    Color borderColor, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: textColor, fontSize: 13),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color textColor,
    required Color borderColor,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required Color textColor,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value.day.toString().padLeft(2, '0')}/'
                    '${value.month.toString().padLeft(2, '0')}/${value.year}',
          style: TextStyle(color: textColor, fontSize: 13),
        ),
      ),
    );
  }
}
