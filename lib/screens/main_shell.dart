import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'report_form_screen.dart';
import 'reports_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((a) => a.user!.isStaff);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onSeeAll: () => setState(() => _index = 1)),
          const ReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      // Staff review reports; only students can file them.
      floatingActionButton: isStaff
          ? null
          : FloatingActionButton(
              onPressed: _openForm,
              shape: const CircleBorder(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: isStaff ? null : const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        height: 64,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.description_outlined,
              label: 'Reports',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            if (!isStaff)
              const SizedBox(
                width: 72,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('Report',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted)),
                  ),
                ),
              ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
