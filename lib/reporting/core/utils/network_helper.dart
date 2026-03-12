import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkHelper {
  // Not a safe way to check internet
  // it just checks if device has any connected network or not
  // But does not check whether the network actually working or not
  // Modify it according to the requirement
  static Future<bool> hasNetworkConnection() async {
    var result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
