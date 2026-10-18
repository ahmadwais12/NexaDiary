import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utilities/app_theme.dart';
import '../../core/utilities/responsive_utils.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  void _showQuickAddSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final r = ResponsiveUtils(ctx);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.quickAddMaxWidth),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quick Add',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Options grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickOption(
                      context,
                      icon: Icons.edit_note_rounded,
                      label: 'Note',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/note/new');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickOption(
                      context,
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Task',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/task/new');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickOption(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Reminder',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/reminder/new');
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickOption(
                      context,
                      icon: Icons.schedule_outlined,
                      label: 'Timetable',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/timetable-event/new');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickOption(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: 'Calendar',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/calendar-event/new');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Empty spacer to keep grid aligned
                  Expanded(child: Container()),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
    },
    );
  }

  Widget _buildQuickOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/notes')) return 1;
    if (location.startsWith('/tasks')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.28 : 0.12,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                // Index 2 = center Quick Add button (skip it)
                // Actual nav indices: 0=Home, 1=Notes, 2=Tasks(mapped to index 3), 3=More
                int targetIndex;
                if (index < 2) {
                  targetIndex = index; // Home=0, Notes=1
                } else if (index == 2) {
                  // Quick Add button — show sheet, don't navigate
                  _showQuickAddSheet(context);
                  return;
                } else {
                  targetIndex = index - 1; // Tasks=2, More=3
                }
                navigationShell.goBranch(
                  targetIndex,
                  initialLocation: targetIndex == selectedIndex,
                );
              },
              height: ResponsiveUtils(context).navBarHeight,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 400),
              destinations: [
                // Home
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                // Notes
                const NavigationDestination(
                  icon: Icon(Icons.edit_note_outlined),
                  selectedIcon: Icon(Icons.edit_note_rounded),
                  label: 'Notes',
                ),
                // Quick Add (center) — non-navigating
                NavigationDestination(
                  icon: const SizedBox.shrink(),
                  selectedIcon: const SizedBox.shrink(),
                  label: '',
                ),
                // Tasks
                const NavigationDestination(
                  icon: Icon(Icons.check_circle_outline),
                  selectedIcon: Icon(Icons.check_circle_rounded),
                  label: 'Tasks',
                ),
                // More
                const NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating center Quick Add button on top of nav bar
      floatingActionButton:        Transform.translate(
        offset: const Offset(0, 16),
        child: Builder(
          builder: (ctx) {
            final r = ResponsiveUtils(ctx);
            return SizedBox(
              width: r.fabSize,
              height: r.fabSize,
              child: HeroMode(
                enabled: false,
                child: FloatingActionButton(
                  heroTag: 'hero_shell_quick_add',
                  onPressed: () => _showQuickAddSheet(context),
                  elevation: 6,
                  backgroundColor: AppTheme.primaryColor,
                  shape: const CircleBorder(),
                  child: Icon(Icons.add_rounded, size: r.fabIconSize, color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}


