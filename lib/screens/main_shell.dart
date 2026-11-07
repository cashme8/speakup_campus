import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'report_form_screen.dart';
import 'reports_screen.dart';

/// Bottom-navigation container. The tab index is UI-only state, so a local
/// setState is appropriate here; app data lives in the providers.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  void _openReports(IncidentStatus? status) {
    context.read<IncidentProvider>().showOwnReports(status: status);
    _goTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((a) => a.user?.isStaff ?? false);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onOpenReports: _openReports,
            onOpenProfile: () => _goTo(2),
          ),
          const ReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      // Staff review reports; only students file them.
      floatingActionButton: isStaff
          ? null
          : FloatingActionButton(
              onPressed: () => ReportFormScreen.open(context),
              tooltip: 'Report an issue',
              shape: const CircleBorder(),
              elevation: 4,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, size: 30),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black12,
        elevation: 8,
        shape: isStaff ? null : const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        height: 66,
        // Two equal halves around the centre-docked button, so the "Report"
        // label sits exactly under it.
        child: Row(
          children: [
            Expanded(
              child: Row(children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                  selected: _index == 0,
                  onTap: () => _goTo(0),
                ),
                _NavItem(
                  icon: Icons.description_outlined,
                  selectedIcon: Icons.description_rounded,
                  label: isStaff ? 'Review' : 'Reports',
                  selected: _index == 1,
                  onTap: () => _goTo(1),
                ),
              ]),
            ),
            if (!isStaff)
              const SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 26), // same space as an icon + gap
                    Text('Report',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted)),
                  ],
                ),
              ),
            Expanded(
              child: Row(children: [
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profile',
                  selected: _index == 2,
                  onTap: () => _goTo(2),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
