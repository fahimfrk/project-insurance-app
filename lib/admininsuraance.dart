import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/login.dart';
import 'package:insurance/quickactions/add_customer.dart';
import 'package:insurance/quickactions/detailedclientview.dart';
import 'package:insurance/quickactions/fileclaim.dart';
import 'package:insurance/quickactions/renewpolicy.dart';
import 'package:insurance/quickactions/viewclientlist.dart';
import 'package:insurance/services/supabase_service.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'urgent':
      return Colors.red;
    case 'upcoming':
      return Colors.orange;
    case 'active':
      return Colors.green;
    case 'lapsed':
      return Colors.red.shade900;
    default:
      return Colors.blueGrey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'urgent':
      return 'Urgent';
    case 'upcoming':
      return 'Upcoming';
    case 'active':
      return 'Active';
    case 'lapsed':
      return 'Lapsed';
    default:
      return status;
  }
}

class InsuranceDashboard extends StatefulWidget {
  const InsuranceDashboard({super.key});

  @override
  State<InsuranceDashboard> createState() => _InsuranceDashboardState();
}

class _InsuranceDashboardState extends State<InsuranceDashboard> {
  int navIndex = 0;
  String selectedFilter = 'All';
  bool isRefreshing = false;

  final List<String> filters = const ['All', 'Active', 'Expiring', 'Lapsed'];

  DashboardMetrics _metrics = const DashboardMetrics();
  List<Map<String, String>> _recentPolicies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final metrics = await SupabaseService.getDashboardMetrics();
      final recent = await SupabaseService.getRecentPolicies(limit: 6);
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _recentPolicies = recent;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // Quick actions button
  Widget quickaction(String label, IconData icon, Color colr, int tapvalue) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        switch (tapvalue) {
          case 1:
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const addcustomer(mode: 0)),
            );
            _loadDashboardData();
            break;
          case 2:
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Sales()),
            );
            _loadDashboardData();
            break;
          case 3:
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RenewPolicyScreen()),
            );
            _loadDashboardData();
            break;
          case 4:
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FileClaimScreen()),
            );
            _loadDashboardData();
            break;
          case 5:
          case 6:
          case 7:
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Sales()),
            );
            _loadDashboardData();
            break;
          case 8:
            await _loadDashboardData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dashboard synchronized with Supabase')),
              );
            }
            break;
        }
      },
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: colr.withValues(alpha: 0.3), width: 1.8),
          boxShadow: [
            BoxShadow(color: colr.withValues(alpha: 0.15), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colr, size: 22),
            SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                overflow: TextOverflow.ellipsis,
                color: colr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget hiuser(bool isDark) {
    return Container(
      height: 70,
      margin: EdgeInsets.only(top: 8, bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Color(0xFF0F3D33), Color(0xFF064E3B)]
              : [Color(0xFFE0F7F1), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Color(0xFF14B8A6).withValues(alpha: 0.4)
              : Color(0xFFA7F3D0).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hi, ${SupabaseService.currentUserName} 👋',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Here is your dashboard overview',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2DD4BF), const Color(0xFF34D399)]
                    : [const Color(0xFF0D9488), const Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488))
                      .withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                SupabaseService.currentUserName.isNotEmpty
                    ? SupabaseService.currentUserName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(bool isDark, Color cardColor, Color textColor) {
    return Container(
      height: 46,
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Color(0xFF3A3A3A) : Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 13, color: textColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Search customers or policies',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ),
          Icon(
            Icons.tune_rounded,
            size: 18,
            color: isDark ? Color(0xFF34D399) : Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final selected = f == selectedFilter;
          final accent = isDark ? Color(0xFF34D399) : Color(0xFF059669);
          return ChoiceChip(
            label: Text(f),
            selected: selected,
            onSelected: (_) => setState(() => selectedFilter = f),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            selectedColor: accent,
            backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
            side: BorderSide(
              color: selected
                  ? Colors.transparent
                  : (isDark ? Color(0xFF3A3A3A) : Color(0xFFE5E7EB)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10),
          );
        },
      ),
    );
  }

  void _showSettingsDialog() {
    final email = SupabaseService.currentUserEmail ?? 'Not logged in';
    final name = SupabaseService.currentUserName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.settings_outlined, color: Color(0xFF059669)),
            SizedBox(width: 10),
            Text('Account & Backend'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: $name', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Email: $email', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Backend: Supabase Cloud', style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('Project: xpdtgngkkjihmconczuy', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await SupabaseService.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _recentPolicyTile(Map<String, String> item, bool isDark) {
    final color = _statusColor(item['status'] ?? 'active');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (item['id'] != null && item['id']!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InsuranceDetailView(docid: item['id']!),
            ),
          ).then((_) => _loadDashboardData());
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car_filled_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['customer'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item['type']} · ${item['vehicle']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(item['status'] ?? 'active'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['note'] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _navItem(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
    bool isDark,
  ) {
    return NavigationDestination(
      icon: Icon(icon, size: 18),
      selectedIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Color(0xFF2DD4BF), Color(0xFF34D399)]
                : [Color(0xFF0D9488), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Color(0xFF2DD4BF) : Color(0xFF0D9488))
                  .withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(selectedIcon, color: Colors.white, size: 22),
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auto theme detection: reads the device/system brightness directly from
    // MediaQuery, so this dashboard automatically switches its light/dark
    // palette whenever the system theme changes — no manual toggle needed.
    final bool isDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final bgColor = isDark ? Color(0xFF0F1714) : Color(0xFFF6FBF8);
    final cardColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Color(0xFF1A1A1A);
    final accent = isDark ? Color(0xFF34D399) : Color(0xFF059669);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: cardColor,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦ ',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF00E5A0)
                    : const Color(0xFF059669),
              ),
            ),
            Text(
              "Insurance Dashboard",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Account & Backend',
            onPressed: _showSettingsDialog,
            icon: Icon(Icons.account_circle_outlined, color: textColor),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              await _loadDashboardData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dashboard refreshed')),
                );
              }
            },
            icon: Icon(Icons.refresh_rounded, color: textColor),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await SupabaseService.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              }
            },
            icon: Icon(Icons.logout_rounded, color: textColor),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const addcustomer(mode: 0)),
          );
          _loadDashboardData();
        },
        backgroundColor: accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  );
                }
                return TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                );
              }),
            ),
            child: NavigationBar(
              height: 58,
              elevation: 0,
              backgroundColor: cardColor,
              surfaceTintColor: Colors.transparent,
              selectedIndex: navIndex,
              onDestinationSelected: (value) async {
                setState(() => navIndex = value);
                if (value == 1) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Sales()),
                  );
                  _loadDashboardData();
                  if (mounted) setState(() => navIndex = 0);
                } else if (value == 2) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RenewPolicyScreen(),
                    ),
                  );
                  _loadDashboardData();
                  if (mounted) setState(() => navIndex = 0);
                } else if (value == 3) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FileClaimScreen(),
                    ),
                  );
                  _loadDashboardData();
                  if (mounted) setState(() => navIndex = 0);
                } else if (value == 4) {
                  _showSettingsDialog();
                  if (mounted) setState(() => navIndex = 0);
                }
              },
              indicatorColor: Colors.transparent,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                _navItem(
                  Icons.dashboard_outlined,
                  Icons.dashboard_rounded,
                  'Dashboard',
                  0,
                  isDark,
                ),
                _navItem(
                  Icons.people_alt_outlined,
                  Icons.people_alt_rounded,
                  'Customers',
                  1,
                  isDark,
                ),
                _navItem(
                  Icons.policy_outlined,
                  Icons.policy_rounded,
                  'Policies',
                  2,
                  isDark,
                ),
                _navItem(
                  Icons.support_agent_outlined,
                  Icons.support_agent,
                  'Claims',
                  3,
                  isDark,
                ),
                _navItem(
                  Icons.settings_outlined,
                  Icons.settings_rounded,
                  'Settings',
                  4,
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: accent,
          backgroundColor: cardColor,
          onRefresh: () async {
            setState(() => isRefreshing = true);
            await _loadDashboardData();
            if (mounted) setState(() => isRefreshing = false);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListView(
              children: [
                hiuser(isDark),
                _searchBar(isDark, cardColor, textColor),
                _filterChips(isDark),
                SizedBox(height: 6),
                custommainheading(
                  color: Colors.blue,
                  label: 'Live Actions',
                  isDark: isDark,
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width:
                          (MediaQuery.of(context).size.width - 12 * 2 - 10) / 2,
                      child: DashboardCard(
                        title: 'Expired Policies',
                        subtitle: 'Expired in last 30–90 Days',
                        count: 2,
                        color: Colors.red,
                        icon: Icons.cancel_outlined,
                      ),
                    ),
                    SizedBox(
                      width:
                          (MediaQuery.of(context).size.width - 12 * 2 - 10) / 2,
                      child: DashboardCard(
                        title: 'Immediate Action',
                        subtitle: 'Expiring in 0–7 Days',
                        count: 25,
                        color: const Color.fromARGB(255, 236, 117, 13),
                        icon: Icons.warning_rounded,
                      ),
                    ),
                    SizedBox(
                      width:
                          (MediaQuery.of(context).size.width - 12 * 2 - 10) / 2,
                      child: DashboardCard(
                        title: 'Upcoming Renewels',
                        subtitle: 'Expiring in a month',
                        count: 25,
                        color: const Color.fromARGB(255, 7, 132, 117),
                        icon: Icons.warning_rounded,
                      ),
                    ),
                    SizedBox(
                      width:
                          (MediaQuery.of(context).size.width - 12 * 2 - 10) / 2,
                      child: DashboardCard(
                        title: 'Renewed This Month',
                        subtitle: '30 days',
                        count: 25,
                        color: const Color.fromARGB(255, 60, 168, 10),
                        icon: Icons.warning_rounded,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),

                SizedBox(height: 6),
                custommainheading(
                  color: const Color.fromARGB(255, 232, 200, 17),
                  label: 'Quick Actions',
                  isDark: isDark,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    quickaction(
                      'Add      Customer',
                      Icons.person_add_alt_1,
                      Color(0xFF3B82F6),
                      1,
                    ),
                    quickaction(
                      'New           Policy',
                      Icons.add_box_outlined,
                      Color(0xFF059669),
                      2,
                    ),
                    quickaction(
                      'Renew          Policy',
                      Icons.autorenew_rounded,
                      Color(0xFF8B5CF6),
                      3,
                    ),
                    quickaction(
                      'File              Claim',
                      Icons.assignment_late_outlined,
                      Color(0xFFF59E0B),
                      4,
                    ),
                    quickaction(
                      'Reports',
                      Icons.insert_chart_outlined_rounded,
                      Color(0xFF14B8A6),
                      5,
                    ),
                    quickaction(
                      'Reports',
                      Icons.insert_chart_outlined_rounded,
                      Color.fromARGB(255, 184, 20, 135),
                      6,
                    ),
                    quickaction(
                      'Reports',
                      Icons.insert_chart_outlined_rounded,
                      Color.fromARGB(255, 56, 184, 20),
                      7,
                    ),
                    quickaction(
                      'Back Up',
                      Icons.insert_chart_outlined_rounded,
                      Color.fromARGB(255, 140, 20, 173),
                      8,
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    custommainheading(
                      color: Color(0xFFF97316),
                      label: 'Recent Policies',
                      isDark: isDark,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                ...recentPolicies.map(
                  (item) => _recentPolicyTile(item, isDark),
                ),
                SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//custom widgets

// Custom widgets with theme support
class custommainheading extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const custommainheading({
    super.key,
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

//dashboard immediate info

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final IconData icon;
  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.transparent,
      shadowColor: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .55), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: .15),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
