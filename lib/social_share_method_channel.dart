import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'social_share_platform_interface.dart';

/// An implementation of [SocialSharePlatform] that uses method channels.
class MethodChannelSocialShare extends SocialSharePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('social_share');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
