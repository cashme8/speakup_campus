import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _openCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        final provider = context.read<IncidentProvider>();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter by category',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All categories'),
                    selected: provider.categoryFilter == null,
                    onSelected: (_) {
                      provider.setCategoryFilter(null);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  for (final c in IncidentCategory.values)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 16, color: c.color),
                      label: Text(c.label),
                      selected: provider.categoryFilter == c,
                      onSelected: (_) {
                        provider.setCategoryFilter(c);
                        Navigator.pop(sheetContext);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final provider = context.watch<IncidentProvider>();
    final list = provider.filtered(user);
    final hasFilters = provider.statusFilter != null ||
        provider.categoryFilter != null ||
        provider.query.isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(user.isStaff ? 'All Reports' : 'My Reports',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                if (hasFilters)
                  TextButton(
                    onPressed: provider.clearFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: provider.setQuery,
                    decoration: const InputDecoration(
                      hintText: 'Search title or location',
                      prefixIcon: Icon(Icons.search, color: AppColors.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: provider.categoryFilter == null
                      ? Colors.white
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openCategorySheet(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.tune,
                          color: provider.categoryFilter == null
                              ? AppColors.ink
                              : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _Pill(
                  label: 'All',
                  selected: provider.statusFilter == null,
                  onTap: () => provider.setStatusFilter(null),
                ),
                for (final s in IncidentStatus.values)
                  _Pill(
                    label: s.label,
                    selected: provider.statusFilter == s,
                    onTap: () => provider.setStatusFilter(s),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      icon: hasFilters
                          ? Icons.search_off
                          : Icons.inbox_outlined,
                      title: hasFilters ? 'No matching reports' : 'No reports yet',
                      message: hasFilters
                          ? 'Try a different search or clear your filters.'
                          : 'Reports will show up here once they are submitted.',
                      actionLabel: hasFilters ? 'Clear filters' : null,
                      onAction: provider.clearFilters,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => IncidentCard(
                      incident: list[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              IncidentDetailScreen(incidentId: list[i].id),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
