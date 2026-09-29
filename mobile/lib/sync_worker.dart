import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'offline_queue.dart';

class SyncWorker {
  final ApiClient api;
  final OfflineOperationQueue queue;
  final Connectivity connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _running = false;
  final Random _random = Random();

  SyncWorker({required this.api, required this.queue, Connectivity? connectivity})
      : connectivity = connectivity ?? Connectivity();

  Future<void> start() async {
    if (_subscription != null) return;
    await _replayIfConnected();
    _subscription = connectivity.onConnectivityChanged.listen((_) => _replayIfConnected());
  }

  Future<void> trigger() => _replayIfConnected();

  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  Future<void> _replayIfConnected() async {
    if (_running || api.token == null) return;
    final statuses = await connectivity.checkConnectivity();
    if (statuses.every((item) => item == ConnectivityResult.none)) return;

    _running = true;
    try {
      while (true) {
        final operations = await queue.load();
        final now = DateTime.now();
        final next = operations.where((op) {
          return op.status == 'PENDING' && !op.nextAttemptAt.isAfter(now);
        }).firstOrNull;
        if (next == null) break;
        await _send(next);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _send(OfflineOperation operation) async {
    try {
      switch (operation.type) {
        case 'SALE_CREATE':
        case 'SALES_RETURN_CREATE':
        case 'SUPPLIER_PAYMENT_CREATE':
        case 'STOCK_REPLENISHMENT':
          if (operation.type == 'SUPPLIER_PAYMENT_CREATE' && operation.payload['method']?.toString() == 'CASH') {
            await queue.update(operation.copyWith(
              status: 'FAILED_LOCAL',
              lastError: 'Cash supplier payments cannot be replayed offline; an active cash session is required.',
            ));
            return;
          }
          final path = switch (operation.type) {
            'SALE_CREATE' => '/sales',
            'SALES_RETURN_CREATE' => '/returns',
            'SUPPLIER_PAYMENT_CREATE' => '/supplier-payments',
            'STOCK_REPLENISHMENT' => '/replenishment/requests',
            _ => throw StateError('Unsupported sync operation type: ${operation.type}'),
          };
          final response = await api
              .post(path, operation.payload, operationKey: operation.operationKey)
              .timeout(const Duration(seconds: 12));
          if (response.statusCode >= 200 && response.statusCode < 300) {
            await queue.remove(operation.operationKey);
            return;
          }

          if (response.statusCode == 409) {
            final replay = await api
                .get('/sync/operations/${Uri.encodeComponent(operation.operationKey)}')
                .timeout(const Duration(seconds: 12));
            if (replay.statusCode >= 200 && replay.statusCode < 300) {
              final data = jsonDecode(replay.body) as Map<String, dynamic>;
              if (data['status'] == 'SUCCEEDED') {
                await queue.remove(operation.operationKey);
                return;
              }
              if (data['status'] == 'FAILED') {
                await queue.update(operation.copyWith(
                  status: 'FAILED_LOCAL',
                  lastError: data['errorMessage'] as String?,
                ));
                return;
              }
              if (data['status'] == 'PROCESSING') {
                await _retry(operation, 'Server is still processing this operation');
                return;
              }
            }
            await _retry(operation, 'HTTP 409: operation is still being resolved');
            return;
          }
          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw Exception('HTTP ${response.statusCode}: ${response.body}');
          }
          throw Exception('HTTP ${response.statusCode}: ${response.body}');

        default:
          await queue.update(operation.copyWith(
            status: 'FAILED_LOCAL',
            lastError: 'Unsupported sync operation type: ${operation.type}',
          ));
      }
    } on http.ClientException catch (e) {
      await _retry(operation, e.toString());
    } on TimeoutException catch (e) {
      await _retry(operation, e.toString());
    } catch (e) {
      final text = e.toString();
      if (RegExp(r'^Exception: HTTP 4\d\d').hasMatch(text)) {
        await queue.update(operation.copyWith(status: 'FAILED_LOCAL', lastError: text));
      } else {
        await _retry(operation, text);
      }
    }
  }

  Future<void> _retry(OfflineOperation operation, String error) async {
    final attempts = operation.attempts + 1;
    if (attempts >= OfflineOperationQueue.maxAttempts) {
      await queue.update(operation.copyWith(
        status: 'FAILED_LOCAL',
        attempts: attempts,
        lastError: 'Maximum automatic retries reached: $error',
        nextAttemptAt: DateTime.now().toUtc(),
      ));
      return;
    }
    final seconds = min(300, pow(2, min(attempts, 8)).toInt()) + _random.nextInt(5);
    await queue.update(operation.copyWith(
      status: 'PENDING',
      attempts: attempts,
      lastError: error,
      nextAttemptAt: DateTime.now().toUtc().add(Duration(seconds: seconds)),
    ));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
