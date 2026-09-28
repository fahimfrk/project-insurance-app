import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/quickactions/add_customer.dart';
import 'package:insurance/quickactions/fileclaim.dart';
import 'package:insurance/quickactions/renewpolicy.dart';
import 'package:insurance/quickactions/viewclientlist.dart';
import 'package:intl/intl.dart';

class DashboardItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double amount;

  const DashboardItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.amount,
  });
}

final List<DashboardItem> dashboardItems = [
  DashboardItem(
    label: "Immediate Action",
    subtitle: "Expiring in 0–7 Days",
    icon: Icons.warning_rounded,
    color: Colors.red,
    amount: 12,
  ),
  DashboardItem(
    label: "Upcoming Renewals",
    subtitle: "Expiring in 8–30 Days",
    icon: Icons.schedule,
    color: Colors.orange,
    amount: 35,
  ),
  DashboardItem(
    label: "Lapsed Policies",
    subtitle: "Expired in last 30–90 Days",
    icon: Icons.cancel_outlined,
    color: Colors.red.shade900,
    amount: 7,
  ),
  DashboardItem(
    label: "Active Policies",
    subtitle: "Current Portfolio",
    icon: Icons.verified_user_outlined,
    color: Colors.blue,
    amount: 428,
  ),
  DashboardItem(
    label: "Renewed This Month",
    subtitle: "Monthly Progress",
    icon: Icons.check_circle_outline,
    color: Colors.green,
    amount: 91,
  ),
];

// Dummy recent-policy records to give the "Recent Policies" section
// something real-looking to display.
final List<Map<String, String>> recentPolicies = [
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

  List<DashboardItem> get _filteredOverview {
    switch (selectedFilter) {
      case 'Active':
        return dashboardItems.where((i) => i.label.contains('Active')).toList();
      case 'Expiring':
        return dashboardItems
            .where(
              (i) =>
                  i.label.contains('Immediate') || i.label.contains('Upcoming'),
            )
            .toList();
      case 'Lapsed':
        return dashboardItems.where((i) => i.label.contains('Lapsed')).toList();
      default:
        return dashboardItems;
    }
  }

  //quick actions button
  Widget quickaction(String label, IconData icon, Color colr, int tapvalue) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        switch (tapvalue) {
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => addcustomer(mode: 0)),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Sales()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RenewPolicyScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FileClaimScreen()),
            );
            break;
          case 4:
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
                'Hi, Magribus 👋',
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
                  color: isDark ? Color(0xFFB0B0B0) : Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Color(0xFF2DD4BF), Color(0xFF34D399)]
                    : [Color(0xFF0D9488), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Color(0xFF2DD4BF) : Color(0xFF0D9488))
                      .withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'M',
                style: TextStyle(
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

  Widget _recentPolicyTile(Map<String, String> item, bool isDark) {
    final color = _statusColor(item['status']!);
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
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
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['customer']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${item['type']} · ${item['vehicle']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Color(0xFFB0B0B0) : Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(item['status']!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                item['note']!,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Color(0xFFB0B0B0) : Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
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
            onPressed: () {},
            icon: Icon(Icons.search_rounded, color: textColor),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_none_rounded, color: textColor),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardColor, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: accent,
        icon: Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
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
              onDestinationSelected: (value) {
                setState(() => navIndex = value);
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
            await Future.delayed(Duration(milliseconds: 800));
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
