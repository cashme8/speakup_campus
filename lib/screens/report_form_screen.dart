import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/repositories.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/category_chip.dart';
import '../widgets/incident_card.dart';
import '../widgets/notice_banner.dart';
import '../widgets/primary_button.dart';
import 'incident_detail_screen.dart';

class ReportFormScreen extends StatefulWidget {
  final IncidentCategory? initialCategory;
  const ReportFormScreen({super.key, this.initialCategory});

  static Future<void> open(BuildContext context,
          {IncidentCategory? category}) =>
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ReportFormScreen(initialCategory: category)),
      );

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _locationDetail = TextEditingController();
  final _picker = ImagePicker();

  // Form-local UI state (not shared with other screens) -> setState is fine.
  late IncidentCategory? _category = widget.initialCategory;
  String? _location;
  XFile? _photo;
  bool _anonymous = false;
  bool _categoryError = false;

  bool get _isDirty =>
      _category != widget.initialCategory ||
      _location != null ||
      _photo != null ||
      _title.text.isNotEmpty ||
      _description.text.isNotEmpty ||
      _locationDetail.text.isNotEmpty;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _locationDetail.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
          source: source, maxWidth: 1600, imageQuality: 75);
      if (file != null) setState(() => _photo = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the camera or gallery. '
              'Check the app permissions and try again.')));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExisting(List<Incident> existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('Open reports at $_location',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'If one of these is your issue, open it and tap “Me too” '
              'instead of filing a duplicate. It helps staff prioritise.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            for (final i in existing)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IncidentCard(
                  incident: i,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    IncidentDetailScreen.open(context, i.id);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Discard this report?'),
        content: const Text('The details you entered will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Keep editing')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Discard')),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _categoryError = _category == null);
    if (!valid || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fix the highlighted fields.')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final user = context.read<AuthProvider>().user!;

    try {
      await context.read<IncidentProvider>().submit(
            user: user,
            title: _title.text,
            description: _description.text,
            category: _category!,
            location: _location!,
            locationDetail: _locationDetail.text,
            isAnonymous: _anonymous,
            photo: _photo == null ? null : File(_photo!.path),
          );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Report submitted. We will keep you updated.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e is AppException
              ? e.message
              : 'Could not submit your report. '
                  'Check your connection and try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<IncidentProvider>();
    final submitting = incidents.submitting;
    final existing =
        _location == null ? const <Incident>[] : incidents.openAt(_location!);

    // Back is intercepted and the form checked *at that moment* (typing does
    // not rebuild this widget, so a build-time `canPop` would be stale).
    // Navigator.pop() after a successful submit bypasses PopScope.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || submitting) return;
        final navigator = Navigator.of(context);
        if (!_isDirty || await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Report an Incident')),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Select a category'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in IncidentCategory.values)
                          CategoryChip(
                            category: c,
                            selected: _category == c,
                            onTap: () => setState(() {
                              _category = c;
                              _categoryError = false;
                            }),
                          ),
                      ],
                    ),
                    if (_categoryError)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, left: 4),
                        child: Text('Select a category',
                            style: TextStyle(
                                color: AppColors.danger, fontSize: 12.5)),
                      ),
                    if (_category == IncidentCategory.safety) ...[
                      const SizedBox(height: 12),
                      const NoticeBanner(
                        'If anyone is in immediate danger, call campus '
                        'security first. This app is not monitored 24/7.',
                        type: NoticeType.warning,
                      ),
                    ],
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Title',
                      hint: 'Briefly describe the issue...',
                      controller: _title,
                      maxLength: maxTitleLength,
                      capitalization: TextCapitalization.sentences,
                      validator: (v) => Validators.lengthBetween(
                          v, minTitleLength, maxTitleLength, 'Title'),
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: 'Description',
                      hint: 'Provide more details about the issue... '
                          'e.g. what happened, when, impact, etc.',
                      controller: _description,
                      maxLines: 4,
                      maxLength: maxDescriptionLength,
                      capitalization: TextCapitalization.sentences,
                      validator: (v) => Validators.lengthBetween(v,
                          minDescriptionLength, maxDescriptionLength,
                          'Description'),
                    ),
                    const SizedBox(height: 8),
                    const FieldLabel('Location'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _location,
                      isExpanded: true,
                      hint: const Text('Select a campus area'),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      borderRadius: BorderRadius.circular(14),
                      dropdownColor: Colors.white,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      items: campusLocations
                          .map((l) =>
                              DropdownMenuItem(
                              value: l,
                              child: Text(l,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _location = v),
                      validator: (v) =>
                          v == null ? 'Select a location' : null,
                    ),
                    if (existing.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      NoticeBanner(
                        '${existing.length} open report'
                        '${existing.length == 1 ? '' : 's'} already at '
                        '$_location. Is yours one of them?',
                        type: NoticeType.info,
                        action: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32)),
                            onPressed: () => _showExisting(existing),
                            child: const Text('View existing reports'),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Room or spot',
                      optionalHint: '(optional)',
                      hint: 'e.g. Room 204, 2nd floor washroom',
                      controller: _locationDetail,
                      maxLength: 60,
                      capitalization: TextCapitalization.sentences,
                      prefixIcon: Icons.meeting_room_outlined,
                    ),
                    const SizedBox(height: 8),
                    const FieldLabel('Add a photo', optionalHint: '(optional)'),
                    const SizedBox(height: 8),
                    _PhotoPicker(
                      photo: _photo,
                      onTap: _showPhotoOptions,
                      onRemove: () => setState(() => _photo = null),
                    ),
                    const SizedBox(height: 16),
                    _AnonymousSwitch(
                      value: _anonymous,
                      onChanged: (v) => setState(() => _anonymous = v),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Submit Report',
                      loading: submitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnonymousSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AnonymousSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        secondary: const Icon(Icons.visibility_off_outlined,
            color: AppColors.primary),
        title: const Text('Report anonymously',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: const Text(
          'Staff and other students won’t see your name. '
          'Your account is still linked so you can track it.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final XFile? photo;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _PhotoPicker(
      {required this.photo, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(File(photo!.path),
                height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _RoundAction(
                    icon: Icons.edit_outlined,
                    tooltip: 'Change photo',
                    onPressed: onTap),
                const SizedBox(width: 8),
                _RoundAction(
                    icon: Icons.close,
                    tooltip: 'Remove photo',
                    onPressed: onRemove),
              ],
            ),
          ),
        ],
      );
    }
    return Semantics(
      button: true,
      label: 'Add a photo',
      excludeSemantics: true,
      child: Material(
        color: AppColors.primarySoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.primary),
                SizedBox(height: 6),
                Text('Tap to take or choose a photo',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _RoundAction(
      {required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
