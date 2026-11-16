import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cord_hearing/src/core/services/chord_ota_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Parsed firmware release manifest from Firebase Storage:
/// `firmware/manifests/<hardware_revision>/vX.Y.Z.json`.
class CloudFirmwareManifest {
  const CloudFirmwareManifest({
    required this.schema,
    required this.version,
    required this.hardware,
    required this.board,
    required this.path,
    required this.size,
    required this.sha256,
    required this.imageHash,
    required this.signing,
    required this.notes,
    required this.git,
    required this.built,
  });

  factory CloudFirmwareManifest.fromJson(Map<String, dynamic> json) {
    return CloudFirmwareManifest(
      schema: (json['schema'] as num?)?.toInt() ?? 1,
      version: (json['version'] as String? ?? '').trim(),
      hardware: (json['hardware'] as String? ?? '').trim(),
      board: (json['board'] as String? ?? '').trim(),
      path: (json['path'] as String? ?? '').trim(),
      size: (json['size'] as num?)?.toInt() ?? 0,
      sha256: (json['sha256'] as String? ?? '').trim(),
      imageHash: (json['image_hash'] as String? ?? '').trim(),
      signing: (json['signing'] as String? ?? '').trim(),
      notes: (json['notes'] as String? ?? '').trim(),
      git: (json['git'] as String? ?? '').trim(),
      built: (json['built'] as String? ?? '').trim(),
    );
  }

  final int schema;
  final String version;
  final String hardware;
  final String board;
  final String path;
  final int size;
  final String sha256;
  final String imageHash;
  final String signing;
  final String notes;
  final String git;
  final String built;

  /// Returns true if [version] is strictly newer than [runningVersion].
  bool isNewerThan(String runningVersion) =>
      compareVersions(version, runningVersion) > 0;

  /// Compares two semantic version strings (e.g. `0.3.2` vs `0.3.0`).
  static int compareVersions(String a, String b) {
    final pa = _parseParts(a);
    final pb = _parseParts(b);
    final len = math.max(pa.length, pb.length);
    for (var i = 0; i < len; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  static List<int> _parseParts(String raw) {
    final cleaned = raw.trim().replaceFirst(RegExp('^[vV]'), '');
    if (cleaned.isEmpty) return const [0, 0, 0];
    return cleaned
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp('[^0-9]'), '')) ?? 0)
        .toList();
  }
}

/// Checks Firebase Storage for CHORD firmware manifests and downloads signed
/// MCUboot `.bin` images with SHA-256 and header verification.
///
/// Manifest folder is keyed by Hardware Revision (`0x2A27`):
/// - `firmware/manifests/nrf5340dk` (Dev Kit)
/// - `firmware/manifests/chord_body_c51ce1a` (Production Body Unit)
class FirebaseOtaService {
  FirebaseOtaService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Checks `firmware/manifests/<hardwareRevision>/` for the newest release
  /// strictly newer than [runningVersion].
  Future<CloudFirmwareManifest?> checkForUpdate({
    required String hardwareRevision,
    required String runningVersion,
  }) async {
    final hw = hardwareRevision.trim();
    if (hw.isEmpty) {
      throw const FormatException(
        'Hardware Revision (0x2A27) has not been read from the CHORD device yet.',
      );
    }

    final manifestsRef = _storage.ref('firmware/manifests/$hw');
    final listResult = await manifestsRef.listAll();
    final jsonItems = listResult.items
        .where((item) => item.name.toLowerCase().endsWith('.json'))
        .toList();

    if (jsonItems.isEmpty) {
      return null;
    }

    // Sort descending by version parsed from filename (e.g. v0.3.2.json)
    jsonItems.sort((a, b) {
      final va = a.name.replaceAll(RegExp(r'\.json$', caseSensitive: false), '');
      final vb = b.name.replaceAll(RegExp(r'\.json$', caseSensitive: false), '');
      return CloudFirmwareManifest.compareVersions(vb, va);
    });

    for (final item in jsonItems) {
      final data = await item.getData(64 * 1024);
      if (data == null || data.isEmpty) continue;

      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is! Map<String, dynamic>) continue;

      final manifest = CloudFirmwareManifest.fromJson(decoded);
      if (manifest.path.isEmpty || manifest.version.isEmpty) continue;
      if (manifest.hardware.isNotEmpty &&
          manifest.hardware.toLowerCase() != hw.toLowerCase()) {
        continue;
      }

      if (runningVersion.trim().isEmpty || manifest.isNewerThan(runningVersion)) {
        return manifest;
      }
      // Since items are sorted newest-first, once we hit <= runningVersion we can stop
      break;
    }

    return null;
  }

  /// Downloads the signed `.bin` referenced by [manifest], verifies its byte
  /// size and SHA-256 digest, and parses its 32-byte MCUboot header.
  Future<McubootImageInfo> downloadAndVerifyFirmware(
    CloudFirmwareManifest manifest,
  ) async {
    final maxBytes = math.max(4 * 1024 * 1024, manifest.size + 65536);
    final ref =
        (manifest.path.startsWith('gs://') ||
            manifest.path.startsWith('https://'))
        ? _storage.refFromURL(manifest.path)
        : _storage.ref(manifest.path);
    final bytes = await ref.getData(maxBytes);

    if (bytes == null || bytes.isEmpty) {
      throw FormatException(
        'Downloaded firmware "${manifest.path}" is empty.',
      );
    }

    if (manifest.size > 0 && bytes.length != manifest.size) {
      throw FormatException(
        'Firmware size mismatch: expected ${manifest.size} bytes, '
        'got ${bytes.length} bytes.',
      );
    }

    final fileName = manifest.path.split('/').last;
    final imageInfo = McubootImageInfo.parse(fileName, Uint8List.fromList(bytes));

    if (manifest.sha256.isNotEmpty &&
        imageInfo.sha256Hex.toLowerCase() != manifest.sha256.toLowerCase()) {
      throw FormatException(
        'SHA-256 verification failed for $fileName. '
        'The downloaded file may be corrupted.',
      );
    }

    return imageInfo;
  }
}
