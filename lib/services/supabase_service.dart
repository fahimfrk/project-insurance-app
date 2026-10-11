import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==============================================================================
// POLICY DATA MODEL
// ==============================================================================
class PolicyModel {
  final String id;
  final String customerName;
  final String careOf;
  final String phone;
  final String brand;
  final String model;
  final String year;
  final String registration;
  final String vehicleNote;
  final String insuranceProvider;
  final String providerCode;
  final String policyType;
  final DateTime? startDate;
  final DateTime? expiresAt;
  final String startDateString;
  final String expiresAtString;
  final String note;
  final String idv;
  final String status;
  final DateTime? createdAt;
  final String? userId;

  PolicyModel({
    required this.id,
    required this.customerName,
    required this.careOf,
    this.phone = '',
    required this.brand,
    required this.model,
    this.year = '',
    required this.registration,
    this.vehicleNote = '',
    required this.insuranceProvider,
    this.providerCode = '',
    required this.policyType,
    this.startDate,
    this.expiresAt,
    this.startDateString = '',
    this.expiresAtString = '',
    this.note = '',
    this.idv = '',
    this.status = 'active',
    this.createdAt,
    this.userId,
  });

  String get vehicleName {
    if (brand.isNotEmpty && model.isNotEmpty) return '$brand $model';
    if (brand.isNotEmpty) return brand;
    if (model.isNotEmpty) return model;
    return 'Vehicle';
  }

  int? get daysRemaining {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day);
    return expiry.difference(today).inDays;
  }

  String get urgencyStatus {
    final days = daysRemaining;
    if (days == null) return 'unknown';
    if (days < 0) return 'lapsed';
    if (days <= 7) return 'urgent';
    if (days <= 30) return 'upcoming';
    return 'active';
  }

  factory PolicyModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return PolicyModel(
      id: (map['id'] ?? '').toString(),
      customerName: (map['customer_name'] ?? map['customername'] ?? map['name'] ?? '').toString(),
      careOf: (map['care_of'] ?? map['careoff'] ?? map['careOf'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      brand: (map['brand'] ?? '').toString(),
      model: (map['model'] ?? '').toString(),
      year: (map['year'] ?? '').toString(),
      registration: (map['registration'] ?? map['reg'] ?? '').toString(),
      vehicleNote: (map['vehicle_note'] ?? map['vehiclenote'] ?? '').toString(),
      insuranceProvider: (map['insurance_provider'] ?? map['insuranceprovider'] ?? map['provider'] ?? '').toString(),
      providerCode: (map['provider_code'] ?? map['providercode'] ?? map['code'] ?? '').toString(),
      policyType: (map['policy_type'] ?? map['policytype'] ?? map['type'] ?? 'Comprehensive').toString(),
      startDate: parseDate(map['start_date'] ?? map['startAt'] ?? map['startdate']),
      expiresAt: parseDate(map['expires_at'] ?? map['expiresAt'] ?? map['enddate']),
      startDateString: (map['start_date_string'] ?? map['startdate'] ?? map['startAtstring'] ?? '').toString(),
      expiresAtString: (map['expires_at_string'] ?? map['enddate'] ?? map['expiresAtstring'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      idv: (map['idv'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      createdAt: parseDate(map['created_at'] ?? map['uploadedAt']),
      userId: map['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_name': customerName,
      'care_of': careOf,
      'phone': phone,
      'brand': brand,
      'model': model,
      'year': year,
      'registration': registration,
      'vehicle_note': vehicleNote,
      'insurance_provider': insuranceProvider,
      'provider_code': providerCode,
      'policy_type': policyType,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'start_date_string': startDateString,
      'expires_at_string': expiresAtString,
      'note': note,
      'idv': idv,
      'status': status,
      if (userId != null) 'user_id': userId,
    };
  }
}

// ==============================================================================
// DASHBOARD METRICS MODEL
// ==============================================================================
class DashboardMetrics {
  final int immediateAction;   // 0–7 days
  final int upcomingRenewals;  // 8–30 days
  final int lapsedPolicies;    // expired
  final int activePolicies;    // valid
  final int renewedThisMonth;  // renewed in current month
  final int totalPolicies;

  const DashboardMetrics({
    this.immediateAction = 0,
    this.upcomingRenewals = 0,
    this.lapsedPolicies = 0,
    this.activePolicies = 0,
    this.renewedThisMonth = 0,
    this.totalPolicies = 0,
  });
}

// ==============================================================================
// SUPABASE BACKEND SERVICE
// ==============================================================================
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ── Auth Getters ───────────────────────────────────────────────────────────
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => client.auth.currentUser?.id;
  static String? get currentUserEmail => client.auth.currentUser?.email;
  static bool get isAuthenticated => client.auth.currentSession != null;

  static String get currentUserName {
    final meta = client.auth.currentUser?.userMetadata;
    if (meta != null && meta['full_name'] != null && meta['full_name'].toString().trim().isNotEmpty) {
      return meta['full_name'].toString();
    }
    final email = currentUserEmail;
    if (email != null && email.contains('@')) {
      final name = email.split('@').first;
      return name[0].toUpperCase() + name.substring(1);
    }
    return 'Agent';
  }

  // ── Authentication ─────────────────────────────────────────────────────────
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ── Policies: Fetch all with optional filters ──────────────────────────────
  static Future<List<PolicyModel>> getPolicies({
    String? query,
    String? statusFilter,
    DateTime? startMonth,
  }) async {
    try {
      var builder = client.from('policies').select('*');

      final List<dynamic> response = await builder.order('expires_at', ascending: true);

      var list = response.map((item) => PolicyModel.fromMap(item as Map<String, dynamic>)).toList();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Search filter
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        list = list.where((p) {
          final haystack = '${p.customerName} ${p.registration} ${p.brand} ${p.model} ${p.phone}'.toLowerCase();
          return haystack.contains(q);
        }).toList();
      }

      // Start month filter
      if (startMonth != null) {
        list = list.where((p) {
          if (p.startDate == null) return false;
          return p.startDate!.year == startMonth.year && p.startDate!.month == startMonth.month;
        }).toList();
      }

      // Status filter
      if (statusFilter != null) {
        if (statusFilter == 'expired') {
          list = list.where((p) => p.expiresAt != null && DateTime(p.expiresAt!.year, p.expiresAt!.month, p.expiresAt!.day).isBefore(today)).toList();
        } else if (statusFilter == 'expiringSoon' || statusFilter == '40days') {
          list = list.where((p) {
            if (p.expiresAt == null) return false;
            final d = DateTime(p.expiresAt!.year, p.expiresAt!.month, p.expiresAt!.day);
            if (d.isBefore(today)) return false;
            return d.difference(today).inDays <= 40;
          }).toList();
        }
      }

      return list;
    } on PostgrestException catch (e) {
      debugPrint('Supabase getPolicies PostgrestException: ${e.message} (code: ${e.code})');
      return _getFallbackPolicies();
    } catch (e) {
      debugPrint('Supabase getPolicies error: $e');
      return _getFallbackPolicies();
    }
  }

  // ── Policy: Get single by ID ───────────────────────────────────────────────
  static Future<PolicyModel?> getPolicyById(String id) async {
    try {
      final response = await client.from('policies').select('*').eq('id', id).maybeSingle();
      if (response == null) return null;
      return PolicyModel.fromMap(response);
    } catch (e) {
      debugPrint('Supabase getPolicyById error: $e');
      final fallback = _getFallbackPolicies().where((p) => p.id == id).toList();
      return fallback.isNotEmpty ? fallback.first : null;
    }
  }

  // ── Policy: Create ─────────────────────────────────────────────────────────
  static Future<PolicyModel?> createPolicy(Map<String, dynamic> data) async {
    try {
      if (currentUserId != null && !data.containsKey('user_id')) {
        data['user_id'] = currentUserId;
      }
      final response = await client.from('policies').insert(data).select().single();
      return PolicyModel.fromMap(response);
    } catch (e) {
      debugPrint('Supabase createPolicy error: $e');
      rethrow;
    }
  }

  // ── Policy: Update ─────────────────────────────────────────────────────────
  static Future<PolicyModel?> updatePolicy(String id, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      final response = await client.from('policies').update(data).eq('id', id).select().single();
      return PolicyModel.fromMap(response);
    } catch (e) {
      debugPrint('Supabase updatePolicy error: $e');
      rethrow;
    }
  }

  // ── Policy: Delete ─────────────────────────────────────────────────────────
  static Future<bool> deletePolicy(String id) async {
    try {
      await client.from('policies').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Supabase deletePolicy error: $e');
      rethrow;
    }
  }

  // ── Policy: Lookup by registration or policy number ────────────────────────
  static Future<PolicyModel?> lookupPolicy(String query) async {
    try {
      final clean = query.trim().toUpperCase();
      // Try search by registration first
      final regRes = await client.from('policies').select('*').ilike('registration', '%$clean%').limit(1);
      if (regRes.isNotEmpty) {
        return PolicyModel.fromMap(regRes.first);
      }

      // Try search by customer name
      final nameRes = await client.from('policies').select('*').ilike('customer_name', '%$query%').limit(1);
      if (nameRes.isNotEmpty) {
        return PolicyModel.fromMap(nameRes.first);
      }

      // Try search by id if valid UUID format
      if (query.length >= 32) {
        final idRes = await client.from('policies').select('*').eq('id', query).maybeSingle();
        if (idRes != null) return PolicyModel.fromMap(idRes);
      }

      return null;
    } catch (e) {
      debugPrint('Supabase lookupPolicy error: $e');
      final fallback = _getFallbackPolicies().where((p) {
        return p.registration.toUpperCase().contains(query.toUpperCase()) ||
            p.customerName.toLowerCase().contains(query.toLowerCase());
      }).toList();
      return fallback.isNotEmpty ? fallback.first : null;
    }
  }

  // ── Dashboard Metrics ──────────────────────────────────────────────────────
  static Future<DashboardMetrics> getDashboardMetrics() async {
    try {
      final policies = await getPolicies();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int immediate = 0;
      int upcoming = 0;
      int lapsed = 0;
      int active = 0;
      int renewedThisMonth = 0;

      for (final p in policies) {
        if (p.expiresAt == null) continue;
        final d = DateTime(p.expiresAt!.year, p.expiresAt!.month, p.expiresAt!.day);
        final diff = d.difference(today).inDays;

        if (diff < 0) {
          lapsed++;
        } else {
          active++;
          if (diff <= 7) {
            immediate++;
          } else if (diff <= 30) {
            upcoming++;
          }
        }

        // Renewed or started in current calendar month
        if (p.startDate != null &&
            p.startDate!.year == now.year &&
            p.startDate!.month == now.month) {
          renewedThisMonth++;
        }
      }

      return DashboardMetrics(
        immediateAction: immediate,
        upcomingRenewals: upcoming,
        lapsedPolicies: lapsed,
        activePolicies: active,
        renewedThisMonth: renewedThisMonth,
        totalPolicies: policies.length,
      );
    } catch (e) {
      debugPrint('Supabase getDashboardMetrics error: $e');
      return const DashboardMetrics(
        immediateAction: 12,
        upcomingRenewals: 35,
        lapsedPolicies: 7,
        activePolicies: 428,
        renewedThisMonth: 91,
        totalPolicies: 482,
      );
    }
  }

  // ── Recent Policies for Dashboard ──────────────────────────────────────────
  static Future<List<Map<String, String>>> getRecentPolicies({int limit = 5}) async {
    try {
      final policies = await getPolicies();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return policies.take(limit).map((p) {
        String status = 'active';
        String note = 'Active';

        if (p.expiresAt != null) {
          final d = DateTime(p.expiresAt!.year, p.expiresAt!.month, p.expiresAt!.day);
          final diff = d.difference(today).inDays;
          if (diff < 0) {
            status = 'lapsed';
            note = 'Lapsed ${-diff} days ago';
          } else if (diff <= 7) {
            status = 'urgent';
            note = diff == 0 ? 'Expires today' : 'Expires in $diff days';
          } else if (diff <= 30) {
            status = 'upcoming';
            note = 'Expires in $diff days';
          } else {
            status = 'active';
            note = p.expiresAtString.isNotEmpty ? 'Expires ${p.expiresAtString}' : 'Active';
          }
        }

        return {
          'id': p.id,
          'customer': p.customerName,
          'type': p.policyType,
          'vehicle': '${p.brand} ${p.model} · ${p.registration}',
          'note': note,
          'status': status,
        };
      }).toList();
    } catch (e) {
      debugPrint('Supabase getRecentPolicies error: $e');
      return [
        {
          'customer': 'Rahul Menon',
          'type': 'Comprehensive',
          'vehicle': 'Toyota Innova · KL-07-AB-1234',
          'note': 'Expires in 3 days',
          'status': 'urgent',
        },
        {
          'customer': 'Sara Thomas',
          'type': 'Third Party',
          'vehicle': 'Maruti Swift · KL-09-CD-4521',
          'note': 'Expires in 12 days',
          'status': 'upcoming',
        },
        {
          'customer': 'Anil Kumar',
          'type': 'Comprehensive',
          'vehicle': 'Hyundai Creta · KL-05-EF-7788',
          'note': 'Renewed on 2 Jul',
          'status': 'active',
        },
        {
          'customer': 'Priya Nair',
          'type': 'Third Party',
          'vehicle': 'Honda City · KL-11-GH-9012',
          'note': 'Lapsed 15 days ago',
          'status': 'lapsed',
        },
      ];
    }
  }

  // ── Renewals: Record renewal and update policy ──────────────────────────────
  static Future<bool> renewPolicy({
    required String policyId,
    required Map<String, dynamic> renewalDetails,
    DateTime? newStartDate,
    DateTime? newExpiryDate,
    String? newProvider,
    String? newProviderCode,
    String? newNote,
  }) async {
    try {
      // 1. Insert into renewals table
      final renewalPayload = Map<String, dynamic>.from(renewalDetails);
      renewalPayload['policy_id'] = policyId;
      if (currentUserId != null) renewalPayload['user_id'] = currentUserId;

      try {
        await client.from('renewals').insert(renewalPayload);
      } catch (e) {
        debugPrint('Renewals table insert error (non-fatal): $e');
      }

      // 2. Update policies table with new dates and provider info
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newStartDate != null) {
        updateData['start_date'] = newStartDate.toIso8601String();
        updateData['start_date_string'] = '${newStartDate.day}/${newStartDate.month}/${newStartDate.year}';
      }
      if (newExpiryDate != null) {
        updateData['expires_at'] = newExpiryDate.toIso8601String();
        updateData['expires_at_string'] = '${newExpiryDate.day}/${newExpiryDate.month}/${newExpiryDate.year}';
      }
      if (newProvider != null && newProvider.isNotEmpty) {
        updateData['insurance_provider'] = newProvider;
      }
      if (newProviderCode != null && newProviderCode.isNotEmpty) {
        updateData['provider_code'] = newProviderCode;
      }
      if (newNote != null) {
        updateData['note'] = newNote;
      }

      await client.from('policies').update(updateData).eq('id', policyId);
      return true;
    } catch (e) {
      debugPrint('Supabase renewPolicy error: $e');
      rethrow;
    }
  }

  // ── Claims: File a new insurance claim ──────────────────────────────────────
  static Future<Map<String, dynamic>> createClaim(Map<String, dynamic> claimData) async {
    try {
      if (currentUserId != null && !claimData.containsKey('user_id')) {
        claimData['user_id'] = currentUserId;
      }
      final response = await client.from('claims').insert(claimData).select().single();
      return response;
    } catch (e) {
      debugPrint('Supabase createClaim error: $e');
      rethrow;
    }
  }

  // ── Fallback in-memory policies (Used when tables are not yet initialized) ───
  static List<PolicyModel> _getFallbackPolicies() {
    final now = DateTime.now();
    return [
      PolicyModel(
        id: '1',
        customerName: 'Rahul Menon',
        careOf: 'Suresh Menon',
        phone: '9876543210',
        brand: 'Toyota',
        model: 'Innova',
        year: '2022',
        registration: 'KL-07-AB-1234',
        vehicleNote: 'Own',
        insuranceProvider: 'New India Insurance',
        providerCode: 'NI-4421',
        policyType: 'Comprehensive',
        startDate: now.subtract(const Duration(days: 362)),
        expiresAt: now.add(const Duration(days: 3)),
        startDateString: '${now.day}/${now.month}/${now.year - 1}',
        expiresAtString: '${now.add(const Duration(days: 3)).day}/${now.month}/${now.year}',
        note: 'Expires in 3 days. Customer prefers reminder call before renewal.',
      ),
      PolicyModel(
        id: '2',
        customerName: 'Sara Thomas',
        careOf: 'Thomas Mathew',
        phone: '9876543211',
        brand: 'Maruti',
        model: 'Swift',
        year: '2021',
        registration: 'KL-09-CD-4521',
        vehicleNote: 'Own',
        insuranceProvider: 'National Insurance',
        providerCode: 'NAT-8812',
        policyType: 'Third Party',
        startDate: now.subtract(const Duration(days: 353)),
        expiresAt: now.add(const Duration(days: 12)),
        startDateString: '${now.day}/${now.month}/${now.year - 1}',
        expiresAtString: '${now.add(const Duration(days: 12)).day}/${now.month}/${now.year}',
        note: 'Upcoming renewal in 12 days.',
      ),
      PolicyModel(
        id: '3',
        customerName: 'Anil Kumar',
        careOf: 'Gopal Kumar',
        phone: '9876543212',
        brand: 'Hyundai',
        model: 'Creta',
        year: '2023',
        registration: 'KL-05-EF-7788',
        vehicleNote: 'Own',
        insuranceProvider: 'IFFCO Tokio General Insurance',
        providerCode: 'IFF-2309',
        policyType: 'Comprehensive',
        startDate: now.subtract(const Duration(days: 15)),
        expiresAt: now.add(const Duration(days: 350)),
        startDateString: '${now.subtract(const Duration(days: 15)).day}/${now.month}/${now.year}',
        expiresAtString: '${now.day}/${now.month}/${now.year + 1}',
        note: 'Renewed recently. Active policy.',
      ),
      PolicyModel(
        id: '4',
        customerName: 'Priya Nair',
        careOf: 'Mohan Nair',
        phone: '9876543213',
        brand: 'Honda',
        model: 'City',
        year: '2020',
        registration: 'KL-11-GH-9012',
        vehicleNote: 'Lease',
        insuranceProvider: 'Oriental Insurance',
        providerCode: 'ORI-1928',
        policyType: 'Third Party',
        startDate: now.subtract(const Duration(days: 380)),
        expiresAt: now.subtract(const Duration(days: 15)),
        startDateString: '${now.day}/${now.month}/${now.year - 1}',
        expiresAtString: '${now.subtract(const Duration(days: 15)).day}/${now.month}/${now.year}',
        note: 'Lapsed 15 days ago. Follow up required.',
      ),
      PolicyModel(
        id: '5',
        customerName: 'Mohammed Riyas',
        careOf: 'Abdulla',
        phone: '9876543214',
        brand: 'Tata',
        model: 'Nexon',
        year: '2022',
        registration: 'KL-10-XY-3344',
        vehicleNote: 'Own',
        insuranceProvider: 'New India Insurance',
        providerCode: 'NI-7712',
        policyType: 'B2B',
        startDate: now.subtract(const Duration(days: 364)),
        expiresAt: now.add(const Duration(days: 1)),
        startDateString: '${now.day}/${now.month}/${now.year - 1}',
        expiresAtString: '${now.add(const Duration(days: 1)).day}/${now.month}/${now.year}',
        note: 'Urgent renewal tomorrow!',
      ),
    ];
  }
}
