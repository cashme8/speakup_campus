import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/category_chip.dart';
import '../widgets/primary_button.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();

  IncidentCategory? _category;
  String? _location;
  XFile? _photo;
  bool _categoryError = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
          source: source, maxWidth: 1600, imageQuality: 80);
      if (file != null) setState(() => _photo = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the camera or gallery.')));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _categoryError = _category == null);
    if (!valid || _category == null) return;

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
            localImagePath: _photo?.path,
          );
      navigator.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Report submitted. We will keep you updated.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not submit your report. Check your connection and try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<IncidentProvider>().submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select a category',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Select a category',
                        style: TextStyle(
                            color: Colors.red.shade600, fontSize: 12.5)),
                  ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Title',
                  hint: 'Briefly describe the issue...',
                  controller: _title,
                  validator: (v) => Validators.minLength(v, 5, 'Title'),
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Description',
                  hint:
                      'Provide more details about the issue... e.g. what happened, when, impact, etc.',
                  controller: _description,
                  maxLines: 4,
                  validator: (v) => Validators.minLength(v, 15, 'Description'),
                ),
                const SizedBox(height: 16),
                const Text('Location',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _location,
                  isExpanded: true,
                  hint: const Text('Select a location'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  items: campusLocations
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _location = v),
                  validator: (v) => v == null ? 'Select a location' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Text('Add a photo ',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text('(optional)',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 8),
                _PhotoPicker(
                  photo: _photo,
                  onTap: _showPhotoOptions,
                  onRemove: () => setState(() => _photo = null),
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
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                tooltip: 'Remove photo',
                onPressed: onRemove,
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: AppColors.muted),
            SizedBox(height: 6),
            Text('Tap to add photos',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
