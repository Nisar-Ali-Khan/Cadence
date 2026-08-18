import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  Stream<bool> get onStatusChange {
    return Connectivity().onConnectivityChanged.map(
          (results) => !results.contains(ConnectivityResult.none),
    );
  }

  Future<bool> isOnlineNow() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}