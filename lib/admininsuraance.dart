import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/login.dart';
import 'package:insurance/quickactions/add_customer.dart';
import 'package:insurance/quickactions/detailedclientview.dart';
import 'package:insurance/quickactions/fileclaim.dart';
import 'package:insurance/quickactions/renewpolicy.dart';
import 'package:insurance/quickactions/viewclientlist.dart';
import 'package:insurance/services/supabase_service.dart';

class InsuranceDashboard extends StatefulWidget {
  const InsuranceDashboard({super.key});

  @override
  State<InsuranceDashboard> createState() => _InsuranceDashboardState();
}

class _InsuranceDashboardState extends State<InsuranceDashboard> {
  bool _loading = true;

  // Exact Colors from the Dribbble Inspiration
  final Color limeGreen = const Color(0xFFB2F068); 
  final Color accentOrange = const Color(0xFFFF6B4A); 
  final Color badgePink = const Color(0xFFFF2E7E); 
  final Color badgeBlue = const Color(0xFF3B82F6); 
  final Color chartCyan = const Color(0xFF00D1D1); 

  DashboardMetrics _metrics = const DashboardMetrics();
  List<Map<String, String>> recentPolicies = [];
  List<Map<String, String>> lapsedPolicies = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      DashboardMetrics realMetrics = await SupabaseService.getDashboardMetrics();
      List<Map<String, String>> realRecent = await SupabaseService.getRecentPolicies(limit: 6);

      if (realMetrics.totalPolicies == 0) {
        _metrics = const DashboardMetrics(
          immediateAction: 0, 
          upcomingRenewals: 3,
          lapsedPolicies: 2,
          activePolicies: 250,
          renewedThisMonth: 22, 
          totalPolicies: 72,
        );
      } else {
        _metrics = realMetrics; 
      }

      final fakePolicies = [
        {
          'id': 'fake1',
          'customer': 'Rahul Menon',
          'type': 'Comprehensive',
          'vehicle': 'Toyota Innova',
          'note': '9:30 - 10:30 AM', 
          'status': 'urgent',
        },
        {
          'id': 'fake2',
          'customer': 'Priya Sharma',
          'type': 'Third Party',
          'vehicle': 'Maruti Swift',
          'note': 'Due Date: Dec 20',
          'status': 'upcoming',
        },
        {
          'id': 'fake3',
          'customer': 'Anil Kumar',
          'type': 'B2B',
          'vehicle': 'Tata Nexon',
          'note': 'Due Date: Dec 15',
          'status': 'lapsed',
        },
      ];

      final allPols = [...realRecent, ...fakePolicies];
      
      if (mounted) {
        setState(() {
          recentPolicies = allPols.take(6).toList();
          lapsedPolicies = allPols.where((p) => p['status'] == 'lapsed' || p['status'] == 'urgent').take(4).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSettingsDialog(bool isDark) {
    final email = SupabaseService.currentUserEmail ?? 'Not logged in';
    final name = SupabaseService.currentUserName;
    
    final dialogBg = isDark ? const Color(0xFF1A1C23) : Colors.white;
    final textMain = isDark ? Colors.white : Colors.black87;
    final textSub = isDark ? Colors.white54 : Colors.black54;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.settings_outlined, color: textMain),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Account', style: GoogleFonts.outfit(fontSize: 18, color: textMain)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: $name', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textMain)),
            const SizedBox(height: 4),
            Text('Email: $email', style: GoogleFonts.outfit(fontSize: 13, color: textSub)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await SupabaseService.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: badgePink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final Color bgCol = isDark ? const Color(0xFF0D0E12) : const Color(0xFFF3F4F8);
    final Color cardCol = isDark ? const Color(0xFF1A1C23) : Colors.white;
    final Color textMain = isDark ? Colors.white : Colors.black87;
    final Color textSub = isDark ? Colors.white70 : Colors.black54;
    final Color iconBorder = isDark ? Colors.white24 : Colors.black12;

    int displayCount = 0;
    String badgeText = "Valid ✅";
    String suffixText = " right now.";

    if (_metrics.immediateAction > 0) {
      displayCount = _metrics.immediateAction;
      badgeText = "Urgent 📈";
      suffixText = " for Today.";
    } else if (_metrics.upcomingRenewals > 0) {
      displayCount = _metrics.upcomingRenewals;
      badgeText = "Upcoming 🗓️";
      suffixText = " coming up.";
    }

    return Scaffold(
      backgroundColor: bgCol,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: isDark ? Colors.white : Colors.black,
              backgroundColor: cardCol,
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), 
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello 👋',
                            style: GoogleFonts.outfit(fontSize: 18, color: textMain, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${SupabaseService.currentUserName}!',
                            style: GoogleFonts.outfit(fontSize: 14, color: textSub),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: iconBorder)),
                            child: Icon(Icons.search_rounded, color: textMain, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: iconBorder)),
                            child: Icon(Icons.notifications_none_rounded, color: textMain, size: 18),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFCA5A5), Color(0xFFD8B4FE), Color(0xFF93C5FD)], 
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFD8B4FE).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text('Today', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                              child: Text('AI-Report', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
                            )
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text("Today's Overview", style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                        const SizedBox(height: 2),
                        Text("You Have $displayCount", style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text("Policies ", style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                              child: Text(badgeText, style: GoogleFonts.outfit(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            Text(suffixText, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LIME GREEN CARD
                      Expanded(
                        flex: 11,
                        child: Container(
                          height: 220,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: limeGreen, 
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: isDark ? [] : [BoxShadow(color: limeGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lapsed Policies', style: GoogleFonts.outfit(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 14),
                              ...lapsedPolicies.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                      child: Icon(Icons.check, color: limeGreen, size: 10), 
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p['customer'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  ],
                                ),
                              )),
                              if (lapsedPolicies.isEmpty) ...[
                                _dummyCheckRow('All caught up!'),
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        flex: 10,
                        child: SizedBox(
                          height: 220,
                          child: Column(
                            children: [
                              // RENEWED CHART CARD
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardCol, 
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator( 
                                              value: 0.3, 
                                              color: badgePink,
                                              backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                              strokeWidth: 5,
                                              strokeCap: StrokeCap.round,
                                            ),
                                            Text('30%', style: GoogleFonts.outfit(color: textMain, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text('Renewed', style: GoogleFonts.outfit(color: textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                                            ),
                                            Text('${_metrics.renewedThisMonth}/${_metrics.totalPolicies} total', style: GoogleFonts.outfit(color: textSub, fontSize: 10)),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // BAR CHART CARD
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: cardCol, 
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _chartBar(28), _chartBar(14), _chartBar(36),
                                          _chartBar(18), _chartBar(24), _chartBar(10),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.track_changes_rounded, color: textSub, size: 12),
                                          const SizedBox(width: 6),
                                          Text('Active: ${_metrics.activePolicies}', style: GoogleFonts.outfit(color: textSub, fontSize: 11)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Policies', style: GoogleFonts.outfit(fontSize: 18, color: textMain, fontWeight: FontWeight.bold)),
                      Icon(Icons.arrow_outward_rounded, color: textSub, size: 18),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  ...recentPolicies.map((item) => _buildRecentItem(item, isDark, cardCol)),
                ],
              ),
            ),
          ),

          // ─── IOS STYLE FLOATING DOCK ───
          Positioned(
            bottom: 24, 
            left: 24,
            right: 24,
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1C23).withOpacity(0.95) : Colors.white.withOpacity(0.95), 
                borderRadius: BorderRadius.circular(35), 
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.1), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.home_filled, color: isDark ? Colors.white : Colors.black, size: 26),
                    onPressed: () {}, 
                  ),
                  IconButton(
                    icon: Icon(Icons.people_alt_rounded, color: isDark ? Colors.white54 : Colors.black45, size: 24),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const Sales())).then((_) => _loadDashboardData());
                    },
                  ),
                  
                  // PREMIUM FLOATING ACTION BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const addcustomer(mode: 0))).then((_) => _loadDashboardData());
                    },
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
                      ),
                      child: Icon(Icons.add_rounded, color: isDark ? Colors.black : Colors.white, size: 28),
                    ),
                  ),

                  IconButton(
                    icon: Icon(Icons.bar_chart_rounded, color: isDark ? Colors.white54 : Colors.black45, size: 24),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FileClaimScreen())).then((_) => _loadDashboardData());
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.person_rounded, color: isDark ? Colors.white54 : Colors.black45, size: 24),
                    onPressed: () => _showSettingsDialog(isDark),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _dummyCheckRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.circle, color: Colors.transparent, size: 10), 
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.outfit(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _chartBar(double height) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(color: chartCyan, borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildRecentItem(Map<String, String> item, bool isDark, Color cardCol) {
    bool isUrgent = item['status'] == 'urgent' || item['status'] == 'lapsed';
    bool isUpcoming = item['status'] == 'upcoming';

    Color badgeColor = isUrgent ? badgePink : (isUpcoming ? accentOrange : limeGreen);
    String badgeText = isUrgent ? 'High' : (isUpcoming ? 'Med' : 'Low');

    Color textMain = isDark ? Colors.white : Colors.black87;
    Color textSub = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: () {
        if (item['id'] != null && !item['id']!.startsWith('fake')) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => InsuranceDetailView(docid: item['id']!))).then((_) => _loadDashboardData());
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is a demo record.')));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardCol, 
          borderRadius: BorderRadius.circular(22),
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
                  child: Text(badgeText, style: GoogleFonts.outfit(color: isUrgent ? Colors.white : Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: badgeBlue, size: 6),
                    const SizedBox(width: 4),
                    Text(item['type'] ?? '', style: GoogleFonts.outfit(color: textMain, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(item['customer'] ?? '', style: GoogleFonts.outfit(color: textMain, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, color: textSub, size: 12),
                const SizedBox(width: 6),
                Text(item['vehicle'] ?? '', style: GoogleFonts.outfit(color: textSub, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['note'] ?? '', style: GoogleFonts.outfit(color: textSub, fontSize: 11)),
                SizedBox(
                  width: 46,
                  height: 22,
                  child: Stack(
                    children: [
                      Positioned(right: 0, child: CircleAvatar(radius: 11, backgroundColor: badgeBlue, child: Text('A', style: GoogleFonts.outfit(fontSize: 9, color: Colors.white)))),
                      Positioned(right: 12, child: CircleAvatar(radius: 11, backgroundColor: badgePink, child: Text('B', style: GoogleFonts.outfit(fontSize: 9, color: Colors.white)))),
                      Positioned(right: 24, child: CircleAvatar(radius: 11, backgroundColor: chartCyan, child: Text('C', style: GoogleFonts.outfit(fontSize: 9, color: Colors.black)))),
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
}