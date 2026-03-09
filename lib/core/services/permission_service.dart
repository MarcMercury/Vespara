import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

/// Permission types supported by the app
enum VesparaPermission {
  camera,
  photos,
  microphone,
  location,
  notifications,
}

/// Permission status
enum VesparaPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unknown,
}

/// Result of a permission request
class PermissionResult {
  const PermissionResult({
    required this.permission,
    required this.status,
    this.message,
  });
  final VesparaPermission permission;
  final VesparaPermissionStatus status;
  final String? message;

  bool get isGranted =>
      status == VesparaPermissionStatus.granted ||
      status == VesparaPermissionStatus.limited;

  bool get isPermanentlyDenied =>
      status == VesparaPermissionStatus.permanentlyDenied;
}

/// Centralized Permission Service
/// Handles all permission requests with proper UX flows
class PermissionService {
  factory PermissionService() => _instance;
  PermissionService._internal();
  static final PermissionService _instance = PermissionService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION PERMISSION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check location permission status
  Future<VesparaPermissionStatus> checkLocationPermission() async {
    if (kIsWeb) return VesparaPermissionStatus.granted;

    final permission = await Geolocator.checkPermission();
    return _mapLocationPermission(permission);
  }

  /// Request location permission with optional rationale
  Future<PermissionResult> requestLocationPermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    if (kIsWeb) {
      return const PermissionResult(
        permission: VesparaPermission.location,
        status: VesparaPermissionStatus.granted,
      );
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const PermissionResult(
        permission: VesparaPermission.location,
        status: VesparaPermissionStatus.denied,
        message:
            'Location services are disabled. Please enable them in Settings.',
      );
    }

    // Check current permission status
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Show rationale before requesting
      if (context != null && showRationale && context.mounted) {
        final shouldRequest = await _showPermissionRationale(
          context,
          VesparaPermission.location,
          'Location Access',
          'Vespara needs your location to show you nearby events, '
              'find matches in your area, and enable Tonight Mode.',
          Icons.location_on_outlined,
        );
        if (!shouldRequest) {
          return const PermissionResult(
            permission: VesparaPermission.location,
            status: VesparaPermissionStatus.denied,
            message: 'Permission request cancelled by user',
          );
        }
      }

      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return const PermissionResult(
        permission: VesparaPermission.location,
        status: VesparaPermissionStatus.permanentlyDenied,
        message:
            'Location permission is permanently denied. Please enable it in Settings.',
      );
    }

    return PermissionResult(
      permission: VesparaPermission.location,
      status: _mapLocationPermission(permission),
    );
  }

  VesparaPermissionStatus _mapLocationPermission(
      LocationPermission permission,) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return VesparaPermissionStatus.granted;
      case LocationPermission.denied:
        return VesparaPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return VesparaPermissionStatus.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return VesparaPermissionStatus.unknown;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMERA & PHOTOS PERMISSION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pick image from gallery with permission handling
  Future<XFile?> pickImageFromGallery({
    BuildContext? context,
    bool showRationale = true,
    int imageQuality = 80,
    double? maxWidth = 1200,
    double? maxHeight = 1200,
  }) async {
    try {
      // Show rationale if context is available
      if (context != null && showRationale && context.mounted) {
        final shouldProceed = await _showPermissionRationale(
          context,
          VesparaPermission.photos,
          'Photo Library Access',
          'Vespara needs access to your photos to let you upload profile pictures and share moments.',
          Icons.photo_library_outlined,
        );
        if (!shouldProceed) return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      return image;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      if (context != null && context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Photo Library',
          'Unable to access your photos. Please grant permission in Settings.',
        );
      }
      return null;
    }
  }

  /// Pick image from camera with permission handling
  Future<XFile?> pickImageFromCamera({
    BuildContext? context,
    bool showRationale = true,
    int imageQuality = 80,
    double? maxWidth = 1200,
    double? maxHeight = 1200,
    CameraDevice preferredCamera = CameraDevice.front,
  }) async {
    try {
      // Show rationale if context is available
      if (context != null && showRationale && context.mounted) {
        final shouldProceed = await _showPermissionRationale(
          context,
          VesparaPermission.camera,
          'Camera Access',
          'Vespara needs camera access to take profile photos and share live moments.',
          Icons.camera_alt_outlined,
        );
        if (!shouldProceed) return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: preferredCamera,
      );

      return image;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      if (context != null && context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Camera',
          'Unable to access your camera. Please grant permission in Settings.',
        );
      }
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages({
    BuildContext? context,
    bool showRationale = true,
    int imageQuality = 80,
    double? maxWidth = 1200,
    double? maxHeight = 1200,
    int? limit,
  }) async {
    try {
      // Show rationale if context is available
      if (context != null && showRationale && context.mounted) {
        final shouldProceed = await _showPermissionRationale(
          context,
          VesparaPermission.photos,
          'Photo Library Access',
          'Vespara needs access to your photos to let you upload profile pictures.',
          Icons.photo_library_outlined,
        );
        if (!shouldProceed) return [];
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        limit: limit,
      );

      return images;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      if (context != null && context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Photo Library',
          'Unable to access your photos. Please grant permission in Settings.',
        );
      }
      return [];
    }
  }

  /// Show image source picker (camera or gallery)
  Future<XFile?> showImageSourcePicker({
    required BuildContext context,
    int imageQuality = 80,
    double? maxWidth = 1200,
    double? maxHeight = 1200,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourcePickerSheet(),
    );

    if (source == null) return null;

    if (source == ImageSource.camera) {
      return pickImageFromCamera(
        context: context,
        showRationale: false, // Already selected camera
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } else {
      return pickImageFromGallery(
        context: context,
        showRationale: false, // Already selected gallery
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RATIONALE DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Show permission rationale before requesting
  Future<bool> _showPermissionRationale(
    BuildContext context,
    VesparaPermission permission,
    String title,
    String description,
    IconData icon,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PermissionRationaleDialog(
        title: title,
        description: description,
        icon: icon,
        permissionName: _getPermissionDisplayName(permission),
      ),
    );

    return result ?? false;
  }

  /// Show permission denied dialog with settings option
  void _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.amber),
            const SizedBox(width: 12),
            Text(
              '$permissionName Required',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!kIsWeb) Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _getPermissionDisplayName(VesparaPermission permission) {
    switch (permission) {
      case VesparaPermission.camera:
        return 'Camera';
      case VesparaPermission.photos:
        return 'Photos';
      case VesparaPermission.microphone:
        return 'Microphone';
      case VesparaPermission.location:
        return 'Location';
      case VesparaPermission.notifications:
        return 'Notifications';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSION STATUS CHECKS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check all permissions and return status map
  Future<Map<VesparaPermission, VesparaPermissionStatus>>
      checkAllPermissions() async {
    final Map<VesparaPermission, VesparaPermissionStatus> statuses = {};

    // Location
    statuses[VesparaPermission.location] = await checkLocationPermission();

    // Camera and photos are checked when used (no pre-check API in image_picker)
    statuses[VesparaPermission.camera] = VesparaPermissionStatus.unknown;
    statuses[VesparaPermission.photos] = VesparaPermissionStatus.unknown;

    return statuses;
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    return Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    if (kIsWeb) return false;
    return Geolocator.openLocationSettings();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UI WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Permission rationale dialog
class _PermissionRationaleDialog extends StatelessWidget {
  const _PermissionRationaleDialog({
    required this.title,
    required this.description,
    required this.icon,
    required this.permissionName,
  });
  final String title;
  final String description;
  final IconData icon;
  final String permissionName;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4A9EFF).withOpacity(0.2),
                      const Color(0xFF4A9EFF).withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: const Color(0xFF4A9EFF),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Not Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9EFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

/// Image source picker sheet
class _ImageSourcePickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(
                  context,
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                _buildOption(
                  context,
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      );

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: const Color(0xFF4A9EFF),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}
