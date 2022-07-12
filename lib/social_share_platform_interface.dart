import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'social_share_method_channel.dart';

abstract class SocialSharePlatform extends PlatformInterface {
  /// Constructs a SocialSharePlatform.
  SocialSharePlatform() : super(token: _token);

  static final Object _token = Object();

  static SocialSharePlatform _instance = MethodChannelSocialShare();

  /// The default instance of [SocialSharePlatform] to use.
  ///
  /// Defaults to [MethodChannelSocialShare].
  static SocialSharePlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SocialSharePlatform] when
  /// they register themselves.
  static set instance(SocialSharePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
