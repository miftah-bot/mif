import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineOperation {
  static const currentSchemaVersion = 2;

  final String operationKey;
  final String type;
  final Map<String, dynamic> payload;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime nextAttemptAt;

  const OfflineOperation({
    required this.operationKey,
    required this.type,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.lastError,
    required this.createdAt,
    required this.nextAttemptAt,
  });

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schemaVersion > currentSchemaVersion) {
      throw const FormatException('Unsupported offline operation schema version');
    }
    final operationKey = json['operationKey'];
    final type = json['type'];
    final payload = json['payload'];
    final createdAt = json['createdAt'];
    if (operationKey is! String || operationKey.isEmpty ||
        type is! String || type.isEmpty ||
        payload is! Map || createdAt is! String) {
      throw const FormatException('Invalid offline operation');
    }
    final created = DateTime.parse(createdAt);
    final nextAttempt = DateTime.parse((json['nextAttemptAt'] as String?) ?? createdAt);
    return OfflineOperation(
      operationKey: operationKey,
      type: type,
      payload: Map<String, dynamic>.from(payload),
      status: (json['status'] as String?) ?? 'PENDING',
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
      createdAt: created,
      nextAttemptAt: nextAttempt,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'operationKey': operationKey,
        'type': type,
        'payload': payload,
        'status': status,
        'attempts': attempts,
        'lastError': lastError,
        'createdAt': createdAt.toIso8601String(),
        'nextAttemptAt': nextAttemptAt.toIso8601String(),
      };

  OfflineOperation copyWith({
    String? status,
    int? attempts,
    String? lastError,
    DateTime? nextAttemptAt,
  }) {
    return OfflineOperation(
      operationKey: operationKey,
      type: type,
      payload: payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError,
      createdAt: createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }
}

class OfflineOperationQueue {
  static const _key = 'offline_operations_v79';
  static const _legacyKey = 'offline_operations_v37';
  static const maxAttempts = 12;
  Future<void> _writeChain = Future.value();

  Future<void> _serialized(Future<void> Function() action) {
    final next = _writeChain.then((_) => action());
    _writeChain = next.catchError((_) {});
    return next;
  }

  Future<List<OfflineOperation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRaw = prefs.getStringList(_key) ?? <String>[];
    final legacyRaw = prefs.getStringList(_legacyKey) ?? <String>[];
    final merged = <String>[...currentRaw, ...legacyRaw];
    final operations = <OfflineOperation>[];
    final seen = <String>{};
    var changed = legacyRaw.isNotEmpty;

    for (final raw in merged) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) throw const FormatException('Offline operation must be an object');
        final operation = OfflineOperation.fromJson(Map<String, dynamic>.from(decoded));
        if (seen.add(operation.operationKey)) operations.add(operation);
        if (!(decoded['schemaVersion'] is num) || (decoded['schemaVersion'] as num).toInt() != OfflineOperation.currentSchemaVersion) changed = true;
      } catch (_) {
        changed = true;
      }
    }
    if (changed) {
      await _save(operations);
      await prefs.remove(_legacyKey);
    }
    return operations;
  }

  Future<void> enqueue({
    required String operationKey,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toUtc();
    return _serialized(() async {
      final operations = await load();
      if (operations.any((op) => op.operationKey == operationKey)) return;
      operations.add(OfflineOperation(
        operationKey: operationKey,
        type: type,
        payload: payload,
        status: 'PENDING',
        attempts: 0,
        lastError: null,
        createdAt: now,
        nextAttemptAt: now,
      ));
      await _save(operations);
    });
  }

  Future<void> remove(String operationKey) async {
    return _serialized(() async {
      final operations = await load();
      operations.removeWhere((op) => op.operationKey == operationKey);
      await _save(operations);
    });
  }

  Future<void> update(OfflineOperation operation) async {
    return _serialized(() async {
      final operations = await load();
      final index = operations.indexWhere((op) => op.operationKey == operation.operationKey);
      if (index < 0) return;
      operations[index] = operation;
      await _save(operations);
    });
  }

  Future<int> pendingCount() async {
    final operations = await load();
    return operations.where((op) => op.status == 'PENDING').length;
  }

  Future<int> failedCount() async {
    final operations = await load();
    return operations.where((op) => op.status == 'FAILED_LOCAL').length;
  }

  Future<void> retryFailed(String operationKey) async {
    return _serialized(() async {
      final operations = await load();
      final index = operations.indexWhere((op) => op.operationKey == operationKey);
      if (index < 0) return;
      operations[index] = operations[index].copyWith(
        status: 'PENDING',
        attempts: 0,
        lastError: null,
        nextAttemptAt: DateTime.now().toUtc(),
      );
      await _save(operations);
    });
  }

  Future<void> _save(List<OfflineOperation> operations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, operations.map((op) => jsonEncode(op.toJson())).toList());
  }
}
