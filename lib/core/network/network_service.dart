import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = false;

  bool get isOnline => _isOnline;

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> checkInternet() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      if (connectivityResults.isEmpty ||
          connectivityResults.any((r) => r == ConnectivityResult.none)) {
        _isOnline = false;
        return false;
      }

      return await _checkReachability();
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

  Future<bool> _checkReachability() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _isOnline = true;
        return true;
      }

      _isOnline = false;
      return false;
    } on SocketException catch (_) {
      _isOnline = false;
      return false;
    } on TimeoutException catch (_) {
      _isOnline = false;
      return false;
    } on OSError catch (_) {
      _isOnline = false;
      return false;
    } catch (_) {
      _isOnline = false;
      return false;
    }
  }

  StreamSubscription<List<ConnectivityResult>> listenForChanges(void Function(bool isOnline) onChange) {
    return _connectivity.onConnectivityChanged.listen((results) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      final online = hasConnection && await _checkReachability();
      onChange(online);
    });
  }
}
