import 'package:flutter/foundation.dart';

@immutable
class PairedDeviceRecord {
  const PairedDeviceRecord({
    required this.remoteId,
    required this.name,
    required this.pairedAt,
    this.firmwareVersion = '',
    this.model = '',
  });

  factory PairedDeviceRecord.fromJson(Map<String, dynamic> json) {
    final rawTime = json['pairedAt'];
    DateTime parsedTime;
    if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else if (rawTime is String) {
      parsedTime =
          DateTime.tryParse(rawTime) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return PairedDeviceRecord(
      remoteId: (json['remoteId'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? 'CHORD Hearing Aid').trim(),
      pairedAt: parsedTime,
      firmwareVersion: (json['firmwareVersion'] as String? ?? '').trim(),
      model: (json['model'] as String? ?? '').trim(),
    );
  }

  final String remoteId;
  final String name;
  final DateTime pairedAt;
  final String firmwareVersion;
  final String model;

  PairedDeviceRecord copyWith({
    String? remoteId,
    String? name,
    DateTime? pairedAt,
    String? firmwareVersion,
    String? model,
  }) {
    return PairedDeviceRecord(
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      pairedAt: pairedAt ?? this.pairedAt,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      model: model ?? this.model,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'remoteId': remoteId,
      'name': name,
      'pairedAt': pairedAt.millisecondsSinceEpoch,
      'firmwareVersion': firmwareVersion,
      'model': model,
    };
  }

  /// Formats a human-readable relative pairing timestamp (e.g. "Paired just now",
  /// "Paired 3 hours ago", "Paired 2 days ago").
  String formatRelativeTime({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(pairedAt);

    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Paired just now';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'Paired $m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'Paired $h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays == 1) {
      return 'Paired yesterday';
    }
    if (diff.inDays < 30) {
      return 'Paired ${diff.inDays} days ago';
    }
    final months = (diff.inDays / 30).floor();
    if (months < 12) {
      return 'Paired $months ${months == 1 ? 'month' : 'months'} ago';
    }
    final years = (diff.inDays / 365).floor();
    return 'Paired $years ${years == 1 ? 'year' : 'years'} ago';
  }
}
