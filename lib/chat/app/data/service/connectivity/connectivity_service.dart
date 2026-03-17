import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../../../../core/utils/logs_helper.dart';
import '../../../../core/utils/network_helper.dart';

/// Reactive connectivity service that tracks network state and emits
/// transition events (offline->online, online->offline).
///
/// Uses [connectivity_plus] for platform-level connectivity monitoring
/// and [NetworkHelper] for the initial check.
class ConnectivityService extends GetxService {
  static const String _tag = 'ConnectivityService';

  final isOnline = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final _transitionController = StreamController<bool>.broadcast();

  /// Emits `true` on offline->online transitions and `false` on
  /// online->offline transitions. Only fires on actual state changes.
  Stream<bool> get onConnectivityChanged => _transitionController.stream;

  /// Initializes the service: checks current connectivity and starts
  /// listening for changes.
  Future<ConnectivityService> init() async {
    // Check initial connectivity
    final hasConnection = await NetworkHelper.hasNetworkConnection();
    isOnline.value = hasConnection;
    LogsHelper.debugLog(
      tag: _tag,
      'Initial connectivity: ${hasConnection ? "online" : "offline"}',
    );

    // Listen for connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);

    return this;
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = isOnline.value;
    final nowOnline = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    isOnline.value = nowOnline;

    // Only emit on actual transitions
    if (wasOnline != nowOnline) {
      LogsHelper.debugLog(
        tag: _tag,
        'Connectivity transition: ${wasOnline ? "online" : "offline"} -> '
            '${nowOnline ? "online" : "offline"}',
      );
      _transitionController.add(nowOnline);
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _transitionController.close();
    super.onClose();
  }
}
