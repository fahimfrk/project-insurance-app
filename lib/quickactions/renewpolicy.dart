import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ---------------------------------------------------------------------
/// RENEW POLICY SCREEN
/// ---------------------------------------------------------------------
/// Lets an agent look up an existing/expiring policy, review its prior
/// details, apply the No-Claim-Bonus, update the IDV, and compute the
/// renewal premium breakup before confirming payment.
/// ---------------------------------------------------------------------
class RenewPolicyScreen extends StatefulWidget {
  const RenewPolicyScreen({super.key});

  @override
  State<RenewPolicyScreen> createState() => _RenewPolicyScreenState();
}

class _RenewPolicyScreenState extends State<RenewPolicyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _searchCtrl = TextEditingController();
  bool _policyFound = false;

  // Existing policy snapshot (would normally come from backend lookup)
  final Map<String, String> _existingPolicy = {
    'policyNumber': 'POL-2025-004521',
    'customer': 'Rahul Menon',
    'vehicle': 'Toyota Innova · KL-07-AB-1234',
    'previousInsurer': 'Same Company',
    'expiryDate': '28 Jul 2026',
    'previousNcb': '25%',
    'previousIdv': '₹8,50,000',
  };

  // Renewal inputs
  String _ncbSlab = '25%';
  final _newIdvCtrl = TextEditingController();
  String _coverageType = 'Comprehensive';
  final _odPremiumCtrl = TextEditingController();
  final _tpPremiumCtrl = TextEditingController();
  final _addOnPremiumCtrl = TextEditingController();
  DateTime? _renewalStartDate;
  String _paymentMode = 'UPI';
  bool _hadClaimLastYear = false;

  final List<String> _ncbSlabs = const [
    '0%',
    '20%',
    '25%',
    '35%',
    '45%',
    '50%',
  ];
  final List<String> _coverageTypes = const [
    'Comprehensive',
    'Third Party Only',
    'Own Damage Only',
  ];
  final List<String> _paymentModes = const [
    'UPI',
    'Credit/Debit Card',
    'Net Banking',
    'Cheque',
    'Cash',
  ];

  double get _odPremium => double.tryParse(_odPremiumCtrl.text) ?? 0;
  double get _tpPremium => double.tryParse(_tpPremiumCtrl.text) ?? 0;
  double get _addOnPremium => double.tryParse(_addOnPremiumCtrl.text) ?? 0;
  double get _ncbDiscount =>
      _odPremium * (double.parse(_ncbSlab.replaceAll('%', '')) / 100);
  double get _subtotal =>
      (_odPremium - _ncbDiscount) + _tpPremium + _addOnPremium;
  double get _gst => _subtotal * 0.18;
  double get _totalPremium => _subtotal + _gst;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newIdvCtrl.dispose();
    _odPremiumCtrl.dispose();
    _tpPremiumCtrl.dispose();
    _addOnPremiumCtrl.dispose();
    super.dispose();
  }

  void _lookupPolicy() {
    if (_searchCtrl.text.trim().isEmpty) {
      _showSnack('Enter a policy number or vehicle number to search');
      return;
    }
    // TODO: replace with real backend lookup
    setState(() {
      _policyFound = true;
      _ncbSlab = _existingPolicy['previousNcb']!;
      _newIdvCtrl.text = _existingPolicy['previousIdv']!.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _renewalStartDate = picked);
  }

  void _submit() {
    if (!_policyFound) {
      _showSnack('Please search and select a policy first');
      return;
    }
    if (_formKey.currentState!.validate()) {
      if (_renewalStartDate == null) {
        _showSnack('Please select the renewal start date');
        return;
      }
      final record = {
        'policyNumber': _existingPolicy['policyNumber'],
        'customer': _existingPolicy['customer'],
        'ncbApplied': _ncbSlab,
        'hadClaimLastYear': _hadClaimLastYear,
        'newIdv': _newIdvCtrl.text.trim(),
        'coverageType': _coverageType,
        'odPremium': _odPremium,
        'tpPremium': _tpPremium,
        'addOnPremium': _addOnPremium,
        'ncbDiscount': _ncbDiscount,
        'gst': _gst,
        'totalPremium': _totalPremium,
        'renewalStartDate': _renewalStartDate!.toIso8601String(),
        'paymentMode': _paymentMode,
      };

      // TODO: persist record to backend / local DB
      debugPrint(record.toString());

      _showSnack('Policy renewed successfully');
      Navigator.of(context).maybePop(record);
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
    final borderColor = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE5E7EB);
    final subText = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        title: Text(
          'Renew Policy',
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
            _sectionHeader('Find Policy', accent, textColor),
            _card(cardColor, borderColor, [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchCtrl,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Policy Number or Vehicle Number',
                        prefixIcon: const Icon(Icons.search, size: 19),
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _lookupPolicy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Find',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            if (_policyFound) ...[
              _sectionHeader('Existing Policy Summary', accent, textColor),
              _card(cardColor, borderColor, [
                _summaryRow(
                  'Policy Number',
                  _existingPolicy['policyNumber']!,
                  textColor,
                  subText,
                ),
                _summaryRow(
                  'Customer',
                  _existingPolicy['customer']!,
                  textColor,
                  subText,
                ),
                _summaryRow(
                  'Vehicle',
                  _existingPolicy['vehicle']!,
                  textColor,
                  subText,
                ),
                _summaryRow(
                  'Expiry Date',
                  _existingPolicy['expiryDate']!,
                  textColor,
                  subText,
                ),
                _summaryRow(
                  'Previous NCB',
                  _existingPolicy['previousNcb']!,
                  textColor,
                  subText,
                ),
                _summaryRow(
                  'Previous IDV',
                  _existingPolicy['previousIdv']!,
                  textColor,
                  subText,
                ),
              ]),
              _sectionHeader('Renewal Details', accent, textColor),
              _card(cardColor, borderColor, [
                SwitchListTile(
                  value: _hadClaimLastYear,
                  onChanged: (v) => setState(() {
                    _hadClaimLastYear = v;
                    if (v) _ncbSlab = '0%';
                  }),
                  title: Text(
                    'Claim made in previous policy year?',
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  activeThumbColor: accent,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                _dropdownField(
                  label: 'No-Claim-Bonus (NCB) Slab',
                  value: _ncbSlab,
                  items: _ncbSlabs,
                  onChanged: (v) => setState(() => _ncbSlab = v!),
                  textColor: textColor,
                  borderColor: borderColor,
                ),
                _textField(
                  _newIdvCtrl,
                  'Updated IDV ₹',
                  Icons.currency_rupee_outlined,
                  textColor,
                  borderColor,
                  keyboardType: TextInputType.number,
                  required: true,
                ),
                _dropdownField(
                  label: 'Coverage Type',
                  value: _coverageType,
                  items: _coverageTypes,
                  onChanged: (v) => setState(() => _coverageType = v!),
                  textColor: textColor,
                  borderColor: borderColor,
                ),
                _dateField(
                  label: 'Renewal Start Date',
                  value: _renewalStartDate,
                  onTap: _pickStartDate,
                  textColor: textColor,
                  borderColor: borderColor,
                ),
              ]),
              _sectionHeader('Premium Breakup', accent, textColor),
              _card(cardColor, borderColor, [
                _textField(
                  _odPremiumCtrl,
                  'Own Damage Premium ₹',
                  Icons.build_circle_outlined,
                  textColor,
                  borderColor,
                  keyboardType: TextInputType.number,
                  required: true,
                  onChanged: (_) => setState(() {}),
                ),
                _textField(
                  _tpPremiumCtrl,
                  'Third Party Premium ₹',
                  Icons.groups_outlined,
                  textColor,
                  borderColor,
                  keyboardType: TextInputType.number,
                  required: true,
                  onChanged: (_) => setState(() {}),
                ),
                _textField(
                  _addOnPremiumCtrl,
                  'Add-on Premium ₹ (optional)',
                  Icons.add_circle_outline,
                  textColor,
                  borderColor,
                  keyboardType: TextInputType.number,
                  required: false,
                  onChanged: (_) => setState(() {}),
                ),
                const Divider(height: 20),
                _summaryRow(
                  'NCB Discount',
                  '- ₹${_ncbDiscount.toStringAsFixed(0)}',
                  textColor,
                  subText,
                ),
                _summaryRow(
                  'Subtotal',
                  '₹${_subtotal.toStringAsFixed(0)}',
                  textColor,
                  subText,
                ),
                _summaryRow(
                  'GST (18%)',
                  '₹${_gst.toStringAsFixed(0)}',
                  textColor,
                  subText,
                ),
                const Divider(height: 20),
                _summaryRow(
                  'Total Renewal Premium',
                  '₹${_totalPremium.toStringAsFixed(0)}',
                  accent,
                  accent,
                  bold: true,
                ),
              ]),
              _sectionHeader('Payment', accent, textColor),
              _card(cardColor, borderColor, [
                _dropdownField(
                  label: 'Payment Mode',
                  value: _paymentMode,
                  items: _paymentModes,
                  onChanged: (v) => setState(() => _paymentMode = v!),
                  textColor: textColor,
                  borderColor: borderColor,
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
                    Icons.autorenew_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Confirm Renewal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _summaryRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: valueColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: labelColor,
            ),
          ),
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
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
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
