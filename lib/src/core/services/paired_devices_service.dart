import 'dart:async';
import 'dart:convert';

import 'package:cord_hearing/src/model/paired_device_record.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure local storage for persisting paired devices per user account
/// using `package:flutter_secure_storage`.
class PairedDevicesStorage {
  PairedDevicesStorage({
    String Function()? accountIdResolver,
    FlutterSecureStorage? secureStorage,
    this.persistToDisk = true,
  }) : _accountIdResolver = accountIdResolver ?? _defaultAccountId,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final String Function() _accountIdResolver;
  final FlutterSecureStorage _secureStorage;
  final bool persistToDisk;
  final Map<String, List<PairedDeviceRecord>> _memoryCache = {};

  static String _defaultAccountId() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final id = user?.uid.trim();
      if (id != null && id.isNotEmpty) return id;
      final email = user?.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {
      // Firebase may not be initialized in unit/widget tests
    }
    return 'local_account';
  }

  String get currentStorageKey {
    final sanitized = _accountIdResolver().replaceAll(
      RegExp('[^a-zA-Z0-9._-]'),
      '_',
    );
    return 'paired_devices_$sanitized';
  }

  Future<List<PairedDeviceRecord>> loadDevices() async {
    final key = currentStorageKey;
    if (_memoryCache.containsKey(key)) {
      return List<PairedDeviceRecord>.unmodifiable(_memoryCache[key]!);
    }

    if (persistToDisk) {
      try {
        final rawJson = await _secureStorage.read(key: key);
        if (rawJson != null && rawJson.isNotEmpty) {
          final decoded = jsonDecode(rawJson);
          if (decoded is List) {
            final records = decoded
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (item) => PairedDeviceRecord.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where((r) => r.remoteId.isNotEmpty)
                .toList()
              ..sort((a, b) => b.pairedAt.compareTo(a.pairedAt));
            _memoryCache[key] = records;
            return List<PairedDeviceRecord>.unmodifiable(records);
          }
        }
      } catch (e) {
        debugPrint('PairedDevicesStorage read error: $e');
      }
    }

    return List<PairedDeviceRecord>.unmodifiable(
      _memoryCache[key] ?? const <PairedDeviceRecord>[],
    );
  }

  Future<List<PairedDeviceRecord>> saveDevices(
    List<PairedDeviceRecord> devices,
  ) async {
    final key = currentStorageKey;
    final sorted = List<PairedDeviceRecord>.from(devices)
      ..sort((a, b) => b.pairedAt.compareTo(a.pairedAt));
    _memoryCache[key] = sorted;

    if (persistToDisk) {
      try {
        final encoded = jsonEncode(sorted.map((d) => d.toJson()).toList());
        await _secureStorage.write(key: key, value: encoded);
      } catch (e) {
        debugPrint('PairedDevicesStorage write error: $e');
      }
    }

    return List<PairedDeviceRecord>.unmodifiable(sorted);
  }

  Future<List<PairedDeviceRecord>> upsertDevice(
    PairedDeviceRecord record,
  ) async {
    if (record.remoteId.trim().isEmpty) {
      return loadDevices();
    }
    final existing = List<PairedDeviceRecord>.from(await loadDevices());
    final index = existing.indexWhere(
      (r) => r.remoteId.toLowerCase() == record.remoteId.toLowerCase(),
    );

    if (index >= 0) {
      final previous = existing[index];
      existing[index] = PairedDeviceRecord(
        remoteId: record.remoteId,
        name: record.name.isNotEmpty ? record.name : previous.name,
        pairedAt: record.pairedAt,
        firmwareVersion: record.firmwareVersion.isNotEmpty
            ? record.firmwareVersion
            : previous.firmwareVersion,
        model: record.model.isNotEmpty ? record.model : previous.model,
      );
    } else {
      existing.insert(0, record);
    }

    return saveDevices(existing);
  }

  Future<List<PairedDeviceRecord>> removeDevice(String remoteId) async {
    final existing = List<PairedDeviceRecord>.from(await loadDevices())
      ..removeWhere(
        (r) => r.remoteId.toLowerCase() == remoteId.toLowerCase(),
      );
    return saveDevices(existing);
  }

  Future<List<PairedDeviceRecord>> clearDevices() async {
    final key = currentStorageKey;
    _memoryCache.remove(key);
    if (persistToDisk) {
      try {
        await _secureStorage.delete(key: key);
      } catch (e) {
        debugPrint('PairedDevicesStorage clear error: $e');
      }
    }
    return const <PairedDeviceRecord>[];
  }
}

final pairedDevicesStorageProvider = Provider<PairedDevicesStorage>((ref) {
  return PairedDevicesStorage();
});

class PairedDevicesNotifier extends Notifier<List<PairedDeviceRecord>> {
  @override
  List<PairedDeviceRecord> build() {
    final storage = ref.watch(pairedDevicesStorageProvider);
    unawaited(_loadInitial(storage));
    return const <PairedDeviceRecord>[];
  }

  Future<void> _loadInitial(PairedDevicesStorage storage) async {
    final loaded = await storage.loadDevices();
    state = loaded;
  }

  Future<void> refresh() async {
    final storage = ref.read(pairedDevicesStorageProvider);
    state = await storage.loadDevices();
  }

  Future<void> recordDevice({
    required String remoteId,
    required String name,
    String firmwareVersion = '',
    String model = '',
    DateTime? pairedAt,
  }) async {
    final cleanId = remoteId.trim();
    if (cleanId.isEmpty) return;
    final cleanName = name.trim().isNotEmpty
        ? name.trim()
        : 'CHORD Hearing Aid';

    final storage = ref.read(pairedDevicesStorageProvider);
    final updated = await storage.upsertDevice(
      PairedDeviceRecord(
        remoteId: cleanId,
        name: cleanName,
        pairedAt: pairedAt ?? DateTime.now(),
        firmwareVersion: firmwareVersion.trim(),
        model: model.trim(),
      ),
    );
    state = updated;
  }

  Future<void> removeDevice(String remoteId) async {
    final storage = ref.read(pairedDevicesStorageProvider);
    final updated = await storage.removeDevice(remoteId);
    state = updated;
  }

  Future<void> clearAll() async {
    final storage = ref.read(pairedDevicesStorageProvider);
    final updated = await storage.clearDevices();
    state = updated;
  }
}

final pairedDevicesProvider =
    NotifierProvider<PairedDevicesNotifier, List<PairedDeviceRecord>>(
  PairedDevicesNotifier.new,
);
