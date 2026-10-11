import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insurance/services/supabase_service.dart';

// ============================================================================
// ADD / EDIT INSURANCE CUSTOMER (Multi-step)
// ============================================================================
class addcustomer extends StatefulWidget {
  /// 0 = add a new customer, 1 = edit an existing one (needs [docid]).
  final int mode;
  final String docid;
  const addcustomer({super.key, required this.mode, this.docid = ''});

  @override
  State<addcustomer> createState() => _addcustomerState();
}

class _addcustomerState extends State<addcustomer> {
  // ── Theme ────────────────────────────────────────────────────────────────
  static const Color _green = Color(0xFF2E7D52);
  static const Color _greenLight = Color(0xFF3FA36B);
  static const Color _bg = Colors.white;
  static const double _pagePadding = 20;
  static const double _radius = 14;

  static const String _other = 'Other';
  static const List<String> _providers = [
    'New India Insurance',
    'National Insurance',
    'IFFCO Tokio General Insurance',
    'Oriental Insurance',
  ];
  static const List<String> _policyTypes = ['B2B', 'Full Cover', 'Third Party'];

  // ── Wizard state ─────────────────────────────────────────────────────────
  final _steps = const ['Customer', 'Vehicle', 'Policy', 'Review'];
  int _step = 0;
  int _maxStep = 0; // furthest step the user has unlocked
  bool _forward = true; // slide direction of the transition
  bool _saving = false;
  bool _loading = false;

  // A fresh key per step, so a leaving and an arriving step never share one.
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int get _lastStep => _steps.length - 1;

  // ── Step 1: customer ─────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _careOfCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // ── Step 2: vehicle ──────────────────────────────────────────────────────
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _regCtrl = TextEditingController();

  // ── Step 3: policy ───────────────────────────────────────────────────────
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _customProviderCtrl = TextEditingController();
  final _codeProviderCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _provider;
  String? _policyType;

  List<TextEditingController> get _controllers => [
    _nameCtrl,
    _careOfCtrl,
    _phoneCtrl,
    _brandCtrl,
    _modelCtrl,
    _yearCtrl,
    _regCtrl,
    _startCtrl,
    _endCtrl,
    _customProviderCtrl,
    _codeProviderCtrl,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_onChanged);
    }
    if (widget.mode == 1) _load();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  bool _filled(TextEditingController c) => c.text.trim().isNotEmpty;

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String get _providerName =>
      _provider == _other ? _customProviderCtrl.text.trim() : (_provider ?? '');

  /// Required checks per step – drive the progress bar and the Continue button.
  List<bool> _requiredChecks(int step) {
    switch (step) {
      case 0:
        return [_filled(_nameCtrl), _filled(_careOfCtrl)];
      case 1:
        return [_filled(_brandCtrl), _filled(_modelCtrl), _filled(_regCtrl)];
      default:
        return [
          _provider != null &&
              (_provider != _other || _filled(_customProviderCtrl)),
          _filled(_codeProviderCtrl),
          _startDate != null,
          _endDate != null,
          _policyType != null,
        ];
    }
  }

  double _progress(int step) {
    if (step >= _lastStep) return 1.0; // review step has no fields
    final checks = _requiredChecks(step);
    return checks.where((c) => c).length / checks.length;
  }

  bool get _allComplete => List.generate(3, _progress).every((p) => p >= 1.0);

  String? _phoneError(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    return v.trim().length == 10 ? null : 'Enter a 10-digit number';
  }

  String? _yearError(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final y = int.tryParse(v.trim());
    if (y == null || y < 1980 || y > DateTime.now().year + 1) {
      return 'Enter a valid year';
    }
    return null;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────
  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = step > _step;
      _step = step;
      if (step > _maxStep) _maxStep = step;
      _formKey = GlobalKey<FormState>();
    });
  }

  void _jumpTo(int step, String message) {
    _goTo(step);
    _snack(message);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step < _lastStep) {
      if (!(_formKey.currentState?.validate() ?? true)) return;
      _goTo(_step + 1);
    } else {
      _save();
    }
  }

  void _back() {
    if (_saving) return;
    if (_step > 0) _goTo(_step - 1);
  }

  // ── Supabase Backend ─────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final policy = await SupabaseService.getPolicyById(widget.docid);
      if (policy != null && mounted) {
        _nameCtrl.text = policy.customerName;
        _careOfCtrl.text = policy.careOf;
        _phoneCtrl.text = policy.phone;
        _brandCtrl.text = policy.brand;
        _modelCtrl.text = policy.model;
        _yearCtrl.text = policy.year;
        _regCtrl.text = policy.registration;
        _noteCtrl.text = policy.vehicleNote.isNotEmpty ? policy.vehicleNote : policy.note;

        if (_providers.contains(policy.insuranceProvider)) {
          _provider = policy.insuranceProvider;
        } else if (policy.insuranceProvider.isNotEmpty) {
          _provider = _other;
          _customProviderCtrl.text = policy.insuranceProvider;
        }

        _codeProviderCtrl.text = policy.providerCode;

        if (_policyTypes.contains(policy.policyType)) {
          _policyType = policy.policyType;
        } else if (policy.policyType.isNotEmpty) {
          _policyType = policy.policyType;
        }

        _startDate = policy.startDate;
        _endDate = policy.expiresAt;
        if (_startDate != null) _startCtrl.text = _fmt(_startDate!);
        if (_endDate != null) _endCtrl.text = _fmt(_endDate!);
      }
    } catch (e) {
      if (mounted) _snack('Failed to load customer: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'customer_name': _nameCtrl.text.trim(),
      'care_of': _careOfCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'brand': _brandCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'year': _yearCtrl.text.trim(),
      'registration': _regCtrl.text.trim(),
      'vehicle_note': _noteCtrl.text.trim(),
      'insurance_provider': _providerName,
      'provider_code': _codeProviderCtrl.text.trim(),
      'policy_type': _policyType ?? 'Comprehensive',
      if (_startDate != null) 'start_date': _startDate!.toIso8601String(),
      if (_endDate != null) 'expires_at': _endDate!.toIso8601String(),
      'start_date_string': _startCtrl.text.trim(),
      'expires_at_string': _endCtrl.text.trim(),
      'note': _noteCtrl.text.trim(),
    };

    try {
      if (widget.mode == 1 && widget.docid.isNotEmpty) {
        await SupabaseService.updatePolicy(widget.docid, payload);
        if (mounted) {
          await _showSuccess('Customer & policy updated successfully.');
        }
      } else {
        await SupabaseService.createPolicy(payload);
        if (mounted) {
          await _showSuccess('New customer & policy created successfully.');
        }
      }
    } catch (e) {
      if (mounted) {
        _snack('Error saving: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showSuccess(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _green),
            const SizedBox(width: 10),
            Text(widget.mode == 1 ? 'Updated!' : 'Customer added!'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ── Small UI building blocks ─────────────────────────────────────────────
  InputDecoration _decoration({
    String? hint,
    IconData? icon,
    IconData? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: c, width: w),
    );
    final line = Colors.black.withValues(alpha: 0.08);
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13.5),
      counterText: '',
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: Colors.black38)
          : null,
      suffixIcon: suffix != null
          ? Icon(suffix, size: 20, color: Colors.black38)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(line),
      enabledBorder: border(line, 2),
      focusedBorder: border(_green, 1.4),
      errorBorder: border(Colors.redAccent, 1.2),
      focusedErrorBorder: border(Colors.redAccent, 1.4),
    );
  }

  Widget _label(String text, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.2,
              ),
            ),
            if (!required)
              const TextSpan(
                text: '  Optional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool required = true,
    TextCapitalization cap = TextCapitalization.none,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    TextInputAction action = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),
        TextFormField(
          controller: controller,
          textCapitalization: cap,
          keyboardType: type,
          textInputAction: action,
          inputFormatters: formatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 14.5),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return '$label is required';
            }
            return validator?.call(v);
          },
          decoration: _decoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required DateTime? value,
    required DateTime firstDate,
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          onTap: () async {
            FocusScope.of(context).unfocus();
            var init = value ?? initialDate;
            if (init.isBefore(firstDate)) init = firstDate;
            final picked = await showDatePicker(
              context: context,
              initialDate: init,
              firstDate: firstDate,
              lastDate: DateTime(2100),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: _green),
                ),
                child: child!,
              ),
            );
            if (picked == null || !mounted)
              return; // cancelled – keep old value
            onPicked(picked);
          },
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? '$label is required' : null,
          decoration: _decoration(
            hint: 'dd/mm/yyyy',
            suffix: Icons.calendar_month_outlined,
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? _green : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? _green : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _green.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _gap(List<Widget> items) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const SizedBox(height: 16),
      items[i],
    ],
  ];

  Widget _stepHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _green, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepShell({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> fields,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(icon, title, subtitle),
          const SizedBox(height: 22),
          ...fields,
        ],
      ),
    );
  }

  // ── Step content ─────────────────────────────────────────────────────────
  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _stepShell(
          icon: Icons.person_outline_rounded,
          title: 'Customer details',
          subtitle: 'Who is the policy holder?',
          fields: _customerFields(),
        );
      case 1:
        return _stepShell(
          icon: Icons.directions_car_outlined,
          title: 'Vehicle details',
          subtitle: 'Which vehicle is being insured?',
          fields: _vehicleFields(),
        );
      case 2:
        return _stepShell(
          icon: Icons.shield_outlined,
          title: 'Policy details',
          subtitle: 'Provider, validity and cover type',
          fields: _policyFields(),
        );
      default:
        return _reviewContent();
    }
  }

  List<Widget> _customerFields() => _gap([
    _textField(
      label: 'Customer name',
      hint: 'e.g. Rahman',
      controller: _nameCtrl,
      icon: Icons.person_outline_rounded,
      cap: TextCapitalization.words,
    ),
    _textField(
      label: 'C/O (Care of)',
      hint: 'e.g. Muhammed',
      controller: _careOfCtrl,
      icon: Icons.people_outline_rounded,
      cap: TextCapitalization.words,
    ),
    _textField(
      label: 'Phone number',
      hint: '10-digit mobile number',
      controller: _phoneCtrl,
      icon: Icons.phone_outlined,
      required: false,
      type: TextInputType.phone,
      formatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: _phoneError,
      action: TextInputAction.done,
    ),
  ]);

  List<Widget> _vehicleFields() => _gap([
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _textField(
            label: 'Brand',
            hint: 'Toyota',
            controller: _brandCtrl,
            cap: TextCapitalization.words,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _textField(
            label: 'Model',
            hint: 'Innova',
            controller: _modelCtrl,
            cap: TextCapitalization.words,
          ),
        ),
      ],
    ),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _textField(
            label: 'Year',
            hint: '2022',
            controller: _yearCtrl,
            required: false,
            type: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: _yearError,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _textField(
            label: 'Registration number',
            hint: 'KL01AB1234',
            controller: _regCtrl,
            cap: TextCapitalization.characters,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
            ],
            action: TextInputAction.done,
          ),
        ),
      ],
    ),
    _textField(
      label: 'Lease/Own',
      hint: 'e.g, Write a note',
      controller: _noteCtrl,
      required: false,
      type: TextInputType.multiline,

      cap: TextCapitalization.sentences,
    ),
  ]);

  List<Widget> _policyFields() {
    final start = _startDate;
    return _gap([
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Insurance provider'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in [..._providers, _other])
                _chip(p, _provider == p, () => setState(() => _provider = p)),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _provider == _other
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _textField(
                      label: 'Company name',
                      hint: 'Enter insurance company name',
                      controller: _customProviderCtrl,
                      icon: Icons.business_outlined,
                      cap: TextCapitalization.words,
                      action: TextInputAction.done,
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
      _textField(
        label: 'Provider code',
        hint: 'e.g. Rayid',
        controller: _codeProviderCtrl,
        icon: Icons.tag_rounded,
        action: TextInputAction.done,
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _dateField(
              label: 'Start date',
              controller: _startCtrl,
              value: _startDate,
              firstDate: DateTime(2000),
              initialDate: DateTime.now(),
              onPicked: (d) => setState(() {
                _startDate = d;
                _startCtrl.text = _fmt(d);
                // Expiry can't be before the new start date.
                if (_endDate != null && _endDate!.isBefore(d)) {
                  _endDate = null;
                  _endCtrl.clear();
                }
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dateField(
              label: 'Expiry date',
              controller: _endCtrl,
              value: _endDate,
              firstDate: start ?? DateTime(2000),
              // Policies usually run one year, so open the picker there.
              initialDate: start != null
                  ? DateTime(
                      start.year + 1,
                      start.month,
                      start.day,
                    ).subtract(const Duration(days: 1))
                  : DateTime.now(),
              onPicked: (d) => setState(() {
                _endDate = d;
                _endCtrl.text = _fmt(d);
              }),
            ),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Policy type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _policyTypes)
                _chip(
                  t,
                  _policyType == t,
                  () => setState(() => _policyType = t),
                ),
            ],
          ),
        ],
      ),
    ]);
  }

  // ── Review step ──────────────────────────────────────────────────────────
  Widget _reviewContent() {
    final vehicle = '${_brandCtrl.text.trim()} ${_modelCtrl.text.trim()}'
        .trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          Icons.fact_check_outlined,
          'Review & confirm',
          'Check everything before saving.',
        ),
        const SizedBox(height: 22),
        _reviewCard(
          step: 0,
          title: 'Customer',
          icon: Icons.person_outline_rounded,
          rows: [
            _reviewRow('Name', _nameCtrl.text.trim()),
            _reviewRow('C/O', _careOfCtrl.text.trim()),
            _reviewRow('Phone', _phoneCtrl.text.trim()),
          ],
        ),
        const SizedBox(height: 14),
        _reviewCard(
          step: 1,
          title: 'Vehicle',
          icon: Icons.directions_car_outlined,
          rows: [
            _reviewRow('Vehicle', vehicle),
            _reviewRow('Year', _yearCtrl.text.trim()),
            _reviewRow('Registration', _regCtrl.text.trim().toUpperCase()),
          ],
        ),
        const SizedBox(height: 14),
        _reviewCard(
          step: 2,
          title: 'Policy',
          icon: Icons.shield_outlined,
          rows: [
            _reviewRow('Provider', _providerName),
            _reviewRow('Provider code', _codeProviderCtrl.text.trim()),
            _reviewRow(
              'Start date',
              _startDate != null ? _fmt(_startDate!) : '',
            ),
            _reviewRow('Expiry date', _endDate != null ? _fmt(_endDate!) : ''),
            _reviewRow('Policy type', _policyType ?? ''),
          ],
        ),
      ],
    );
  }

  Widget _reviewCard({
    required int step,
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    final ok = _progress(step) >= 1.0;
    final statusColor = ok ? _green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withAlpha(20), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _green),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ok ? 'Complete' : 'Incomplete',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _goTo(step),
                style: TextButton.styleFrom(
                  foregroundColor: _green,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              empty ? '—' : value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: empty ? Colors.black26 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar (Back / Continue / Submit) ────────────────────────────────
  Widget _buildBottomBar() {
    final isReview = _step == _lastStep;
    final enabled = isReview
        ? (_allComplete && !_saving)
        : _progress(_step) >= 1.0;

    return Padding(
      padding: const EdgeInsets.all(_pagePadding),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _back,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  foregroundColor: _green,
                  side: BorderSide(color: _green.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_radius),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _GradientButton(
              label: isReview
                  ? (widget.mode == 1 ? 'Save Changes' : 'Add Customer')
                  : 'Continue',
              loading: _saving,
              onPressed: enabled ? _next : null,
              colors: const [_green, _greenLight],
              radius: _radius,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final completed = [
      for (var i = 0; i < _steps.length; i++)
        i < _lastStep && i < _maxStep && _progress(i) >= 1.0,
    ];

    return PopScope(
      // System back walks back through the steps before leaving the screen.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: _green, size: 22),
              const SizedBox(width: 8),
              Text(
                widget.mode == 1 ? 'Edit Insurance' : 'New Insurance',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _pagePadding,
                        8,
                        _pagePadding,
                        18,
                      ),
                      child: _StepProgress(
                        steps: _steps,
                        currentStep: _step,
                        maxStep: _maxStep,
                        completed: completed,
                        currentFill: _progress(_step),
                        onStepTap: (i) {
                          if (i != _step && i <= _maxStep) _goTo(i);
                        },
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(_forward ? 0.1 : -0.1, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: ListView(
                          key: ValueKey(_step),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            _pagePadding,
                            0,
                            _pagePadding,
                            24,
                          ),
                          children: [_buildStepContent()],
                        ),
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
              ),
      ),
    );
  }
}

// ============================================================================
// STEP PROGRESS INDICATOR
// Circles for each step; the line after a step fills as its required fields
// are completed, and is full once the step is done.
// ============================================================================
class _StepProgress extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final int maxStep;
  final List<bool> completed;
  final double currentFill;
  final ValueChanged<int> onStepTap;

  const _StepProgress({
    required this.steps,
    required this.currentStep,
    required this.maxStep,
    required this.completed,
    required this.currentFill,
    required this.onStepTap,
  });

  static const Color _green = Color(0xFF2E7D52);

  @override
  Widget build(BuildContext context) {
    final n = steps.length;
    return Stack(
      children: [
        // Connector lines run from the centre of the first circle to the
        // centre of the last one, behind the circles.
        Positioned(
          top: 15.5,
          left: 0,
          right: 0,
          child: Row(
            children: [
              const Expanded(flex: 1, child: SizedBox.shrink()),
              for (var i = 0; i < n - 1; i++)
                Expanded(flex: 2, child: _segment(i)),
              const Expanded(flex: 1, child: SizedBox.shrink()),
            ],
          ),
        ),
        Row(children: [for (var i = 0; i < n; i++) Expanded(child: _node(i))]),
      ],
    );
  }

  Widget _segment(int i) {
    final fill = completed[i] ? 1.0 : (i == currentStep ? currentFill : 0.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fill),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 3,
          backgroundColor: Colors.black.withValues(alpha: 0.08),
          valueColor: const AlwaysStoppedAnimation<Color>(_green),
        ),
      ),
    );
  }

  Widget _node(int i) {
    final active = i == currentStep;
    final done = completed[i];
    final reachable = i <= maxStep;

    final Color fill = done && !active
        ? _green
        : active
        ? Colors.white
        : reachable
        ? const Color(0xFFE6F1EA)
        : const Color(0xFFF1F2F4);

    Widget inner;
    if (done && !active) {
      inner = const Icon(Icons.check_rounded, size: 18, color: Colors.white);
    } else if (done && active) {
      inner = const Icon(Icons.check_rounded, size: 18, color: _green);
    } else {
      inner = Text(
        '${i + 1}',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: (active || reachable) ? _green : Colors.black38,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: reachable ? () => onStepTap(i) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: active ? Border.all(color: _green, width: 2) : null,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Center(child: inner),
          ),
          const SizedBox(height: 6),
          Text(
            steps[i],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? _green
                  : reachable
                  ? Colors.black87
                  : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GRADIENT BUTTON
// ============================================================================
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final List<Color> colors;
  final double radius;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.colors,
    this.loading = false,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || loading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        gradient: enabled ? LinearGradient(colors: colors) : null,
        color: enabled ? null : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: enabled ? Colors.white : Colors.black38,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
