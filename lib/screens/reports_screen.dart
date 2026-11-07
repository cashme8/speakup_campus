import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openCategorySheet() {
    final provider = context.read<IncidentProvider>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter by category',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
            ],
          ),
        ),
      ),
    );
  }

  void _clearAll(IncidentProvider provider) {
    _search.clear();
    provider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    // Null for one frame while signing out, before AuthGate swaps to login.
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final provider = context.watch<IncidentProvider>();
    final list = provider.filtered(user);
    final hasFilters = provider.hasFilters;

    // Keep the text box in sync when filters are reset elsewhere
    // (e.g. a dashboard shortcut).
    // Deferred: changing a controller during build would trigger
    // "setState() called during build".
    if (provider.query.isEmpty && _search.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.query.isEmpty) _search.clear();
      });
    }

    final title = user.isStaff ? 'All Reports' : 'Reports';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                if (hasFilters)
                  TextButton(
                    onPressed: () => _clearAll(provider),
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          if (!user.isStaff)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ReportScope>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white,
                    selectedBackgroundColor: AppColors.primarySoft,
                    selectedForegroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  segments: const [
                    ButtonSegment(
                        value: ReportScope.mine,
                        icon: Icon(Icons.person_outline, size: 18),
                        label: Text('My reports')),
                    ButtonSegment(
                        value: ReportScope.campus,
                        icon: Icon(Icons.apartment_outlined, size: 18),
                        label: Text('Campus')),
                  ],
                  selected: {provider.scope},
                  onSelectionChanged: (s) => provider.setScope(s.first),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: provider.setQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search title, place or details',
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.muted),
                      suffixIcon: provider.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _search.clear();
                                provider.setQuery('');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _FilterButton(
                  active: provider.categoryFilter != null,
                  onTap: _openCategorySheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
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
          if (provider.categoryFilter != null || provider.query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${list.length} result${list.length == 1 ? '' : 's'}'
                  '${provider.categoryFilter == null ? '' : ' in ${provider.categoryFilter!.label}'}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      icon: hasFilters ? Icons.search_off : Icons.inbox_outlined,
                      title:
                          hasFilters ? 'No matching reports' : 'No reports yet',
                      message: hasFilters
                          ? 'Try a different search or clear your filters.'
                          : 'Reports will show up here once they are submitted.',
                      actionLabel: hasFilters ? 'Clear filters' : null,
                      onAction: () => _clearAll(provider),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => IncidentCard(
                      incident: list[i],
                      onTap: () =>
                          IncidentDetailScreen.open(context, list[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Filter by category',
      child: Material(
        color: active ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active ? AppColors.primary : AppColors.border),
            ),
            child: Icon(Icons.tune,
                color: active ? Colors.white : AppColors.ink),
          ),
        ),
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
      child: Semantics(
        selected: selected,
        button: true,
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
      ),
    );
  }
}
