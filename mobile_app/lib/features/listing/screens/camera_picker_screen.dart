import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';

class CameraPickerScreen extends StatefulWidget {
  const CameraPickerScreen({super.key});

  @override
  State<CameraPickerScreen> createState() => _CameraPickerScreenState();
}

class _CameraPickerScreenState extends State<CameraPickerScreen> {
  final _picker = ImagePicker();
  final List<XFile> _selected = [];
  static const int _maxSlots = 9;

  Future<void> _capturePhoto() async {
    if (_selected.length >= _maxSlots) return;
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() => _selected.add(file));
    }
  }

  Future<void> _pickGallery() async {
    final remaining = _maxSlots - _selected.length;
    if (remaining <= 0) return;
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: remaining,
    );
    if (files.isNotEmpty && mounted) {
      setState(() => _selected.addAll(files));
    }
  }

  void _remove(int i) => setState(() => _selected.removeAt(i));

  void _proceed() {
    if (_selected.isEmpty) return;
    context.push('/create-listing', extra: _selected.map((f) => f.path).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _CircleBtn(icon: Icons.close, onTap: () => context.pop()),
                  const Spacer(),
                  Text('${_selected.length}/$_maxSlots',
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: _selected.isEmpty ? _buildEmptyState() : _buildPreviewGrid(),
            ),
            Container(
              color: const Color(0xFF111111),
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'Thu vien',
                        onTap: _pickGallery,
                      ),
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.camera_alt, size: 32, color: Colors.black),
                        ),
                      ),
                      _ControlBtn(
                        icon: Icons.collections_outlined,
                        label: 'Da chon',
                        badge: _selected.isNotEmpty ? '${_selected.length}' : null,
                        onTap: _selected.isEmpty ? null : () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selected.isEmpty ? null : _proceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        disabledBackgroundColor: Colors.grey.shade800,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _selected.isEmpty
                            ? 'Chup anh de tiep tuc'
                            : 'Tiep tuc (${_selected.length} anh)',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 72),
          const SizedBox(height: 16),
          const Text('Chup anh hoac chon tu thu vien',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _capturePhoto,
                icon: const Icon(Icons.camera_alt, color: Colors.white70),
                label: const Text('Chup anh', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickGallery,
                icon: const Icon(Icons.photo_library, color: Colors.white70),
                label: const Text('Thu vien', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewGrid() {
    final total =
        _selected.length < _maxSlots ? _selected.length + 1 : _selected.length;
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: total,
      itemBuilder: (_, i) {
        if (i == _selected.length) {
          return GestureDetector(
            onTap: _pickGallery,
            child: Container(
              color: const Color(0xFF2A2A2A),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  color: Colors.white54, size: 36),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(_selected[i].path), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white38)),
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: () => _remove(i),
                child: Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color ?? Colors.white),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback? onTap;
  const _ControlBtn({required this.icon, required this.label, this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (badge != null)
                Positioned(
                  right: -4, top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppTheme.secondary, shape: BoxShape.circle),
                    child: Text(badge!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}
