import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Vodoravni niz sličica fotografija računa. Dodir otvara fotografiju
/// preko cijelog zaslona (uz zumiranje).
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.paths, this.onRemove});

  final List<String> paths;

  /// Ako je postavljeno, prikazuje gumb za uklanjanje fotografije.
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final path = paths[i];
          return Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showPhotoViewer(context, path),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(path),
                    width: 80,
                    height: 96,
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    errorBuilder: (_, _, _) => Container(
                      width: 80,
                      height: 96,
                      color: AppColors.divider,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onRemove!(path),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> showPhotoViewer(BuildContext context, String path) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 6,
              child: Center(child: Image.file(File(path))),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                tooltip: AppStrings.close,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
