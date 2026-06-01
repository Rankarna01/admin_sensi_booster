import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtil {
  static Future<String> getHardwareId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    
    if (kIsWeb) {
      WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      return webInfo.vendor ?? "web_device";
    }
    
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // Mengambil ID unik perangkat Android
      return androidInfo.id; 
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "ios_device";
    }
    
    return "unknown_device";
  }
}