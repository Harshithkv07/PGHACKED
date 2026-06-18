import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/rent_provider.dart';
import '../../logic/providers/room_provider.dart';
import 'accounts_screen.dart';
import 'add_student_screen.dart';
import 'dashboard_screen.dart';
import 'students_list_screen.dart';
import 'rent_screen.dart';
import 'login_screen.dart';
import '../widgets/monthly_summary_sheet.dart';
import '../widgets/monthly_overview_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AccountsScreen(),
    const AddStudentScreen(),
    const DashboardScreen(),
    const StudentsListScreen(),
    const RentScreen(),
  ];

  final List<String> _titles = [
    'Accounts',
    'Add New Student',
    'Room Dashboard',
    'Students List',
    'Rent Management',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCalendarAndMonth();
    });
  }

  Future<void> _initCalendarAndMonth() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await [
          Permission.calendar,
          Permission.storage,
        ].request();
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }

    if (mounted) {
      final rentProvider = Provider.of<RentProvider>(context, listen: false);
      await rentProvider.checkAndHandleMonthTransition();
      await rentProvider.loadStudents();
      if (mounted) {
        await Provider.of<RoomProvider>(context, listen: false).loadRooms();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Show overview & summary buttons when on Accounts tab
          if (_currentIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.calendar_view_month_rounded),
              tooltip: 'Monthly Overview',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MonthlyOverviewScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'Monthly Summary',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    maxChildSize: 0.9,
                    minChildSize: 0.4,
                    builder: (_, scrollController) =>
                        const MonthlySummarySheet(),
                  ),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'PGHacked',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryAccent,
                        AppColors.secondaryAccent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_work,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorColor,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add Student',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Rent',
          ),
        ],
      ),
    );
  }
}
