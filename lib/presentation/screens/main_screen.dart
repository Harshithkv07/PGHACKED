import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'accounts_screen.dart';
import 'add_student_screen.dart';
import 'dashboard_screen.dart';
import 'students_list_screen.dart';
import 'rent_screen.dart';
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
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'PG Management',
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
