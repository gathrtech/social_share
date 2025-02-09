import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class SocialShare {
  static const MethodChannel _channel = const MethodChannel('social_share');

  static Future<String?> shareInstagramStory(
    String imagePath, {
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? attributionURL,
    String? backgroundImagePath,
    String? linkToCopy,
    String? backgroundVideoPath,
  }) async {
    Map<String, dynamic> args;
    if (Platform.isIOS) {
      args = <String, dynamic>{
        "stickerImage": imagePath,
        "backgroundImage": backgroundImagePath,
        "backgroundTopColor": backgroundTopColor,
        "backgroundBottomColor": backgroundBottomColor,
        "attributionURL": attributionURL,
        "linkToCopy": linkToCopy,
        "backgroundVideoPath": backgroundVideoPath,
      };
    } else {
      File stickerFile = File(imagePath);
      String stickerPath = stickerFile.uri.pathSegments.last;

      String? backgroundAssetName;
      if (backgroundImagePath != null) {
        File backgroundImage = File(backgroundImagePath);
        backgroundAssetName = backgroundImage.uri.pathSegments.last;
      }

      String? backgroundVideoAssetName;
      if (backgroundVideoPath != null) {
        File backgroundVideo = File(backgroundVideoPath);
        backgroundVideoAssetName = backgroundVideo.uri.pathSegments.last;
      }

      args = <String, dynamic>{
        "stickerImage": stickerPath,
        "backgroundImage": backgroundAssetName,
        "backgroundTopColor": backgroundTopColor,
        "backgroundBottomColor": backgroundBottomColor,
        "attributionURL": attributionURL,
        "linkToCopy": linkToCopy,
        "backgroundVideoPath": backgroundVideoAssetName,
      };
    }
    final String? response = await _channel.invokeMethod(
      'shareInstagramStory',
      args,
    );
    return response;
  }

  static Future<String?> shareFacebookStory(
    String imagePath, {
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? attributionURL,
    String? backgroundImagePath,
    String? linkToCopy,
  }) async {
    Map<String, dynamic> args;
    if (Platform.isIOS) {
      args = <String, dynamic>{
        "stickerImage": imagePath,
        "backgroundTopColor": backgroundTopColor,
        "backgroundBottomColor": backgroundBottomColor,
        "attributionURL": attributionURL,
      };
    } else {
      File file = File(imagePath);
      final bytes = file.readAsBytesSync();
      final tempDir = await getTemporaryDirectory();
      final imageName = 'stickerAsset.png';
      final imageDataPath = '${tempDir.path}/$imageName';
      final imageAsList = bytes.buffer.asUint8List();
      file = await File(imageDataPath).create();
      file.writeAsBytesSync(imageAsList);
      args = <String, dynamic>{
        "stickerImage": imageName,
        "backgroundTopColor": backgroundTopColor,
        "backgroundBottomColor": backgroundBottomColor,
        "attributionURL": attributionURL,
      };
    }
    final String? response =
        await _channel.invokeMethod('shareFacebookStory', args);
    return response;
  }

  static Future<String?> shareTwitter(String captionText,
      {List<String> hashTags = const <String>[],
      String url = '',
      String trailingText = '',
      String imagePath = ''}) async {
    Map<String, dynamic> args;
    if (hashTags.isNotEmpty) {
      captionText = captionText + "\n" + hashTags.join(" %23").trim();
    }
    if (Platform.isIOS) {
      if (url.isEmpty) {
        args = <String, dynamic>{
          "captionText": captionText + " ",
          "trailingText": trailingText,
          "image": imagePath
        };
      } else {
        args = <String, dynamic>{
          "captionText": captionText + " ",
          "url": Uri.parse(url).toString(),
          "trailingText": trailingText,
          "image": imagePath
        };
      }
    } else {
      final modifiedUrl = Uri.parse(url).toString().replaceAll('#', "%23");
      if (imagePath.isNotEmpty) {
        File file = File(imagePath);
        final bytes = file.readAsBytesSync();
        final tempDir = await getTemporaryDirectory();
        final imageName = 'stickerAsset.png';
        final imageDataPath = '${tempDir.path}/$imageName';
        final imageAsList = bytes.buffer.asUint8List();
        file = await File(imageDataPath).create();
        file.writeAsBytesSync(imageAsList);
        args = <String, dynamic>{
          "captionText": captionText + " ",
          "url": modifiedUrl,
          "trailingText": trailingText,
          "image": imageName
        };
      } else {
        args = <String, dynamic>{
          "captionText": captionText + " ",
          "url": modifiedUrl,
          "trailingText": trailingText,
          "image": imagePath
        };
      }
    }
    final String? version = await _channel.invokeMethod('shareTwitter', args);
    return version;
  }

  static Future<String?> shareSms(String message,
      {String url = '',
      String trailingText = '',
      String imagePath = ''}) async {
    Map<String, dynamic>? args;
    if (Platform.isIOS) {
      if (url.isEmpty) {
        args = <String, dynamic>{
          "message": message,
          "trailingText": trailingText,
          "image": imagePath
        };
      } else {
        args = <String, dynamic>{
          "message": message + " ",
          "urlLink": Uri.parse(url).toString(),
          "trailingText": trailingText,
          "image": imagePath
        };
      }
    } else {
      if (imagePath.isNotEmpty) {
        File file = File(imagePath);
        final bytes = file.readAsBytesSync();
        final tempDir = await getTemporaryDirectory();
        final imageName = 'stickerAsset.png';
        final imageDataPath = '${tempDir.path}/$imageName';
        final imageAsList = bytes.buffer.asUint8List();
        file = await File(imageDataPath).create();
        file.writeAsBytesSync(imageAsList);
        args = <String, dynamic>{
          "message": "$message $url $trailingText".trim(),
          "image": imageName
        };
      } else {
        args = <String, dynamic>{
          "message": "$message $url $trailingText".trim(),
          "image": imagePath
        };
      }
    }
    final String? version = await _channel.invokeMethod('shareSms', args);
    return version;
  }

  static Future<String?> shareSnapchat({
    required String stickerPath,
    String? urlLink,
    String? caption,
  }) async {
    Map<String, dynamic> args;
    if (Platform.isIOS) {
      args = <String, dynamic>{
        "sticker": stickerPath,
        "urlLink": urlLink,
        "caption": caption,
      };
    } else {
      File file = File(stickerPath);
      String stickerName = file.uri.pathSegments.last;

      args = <String, dynamic>{
        "sticker": stickerName,
        "urlLink": urlLink,
        "caption": caption,
      };
    }

    final String? response = await _channel.invokeMethod('shareSnapchat', args);
    return response;
  }

  static Future<bool?> copyToClipboard(content) async {
    final Map<String, String> args = <String, String>{
      "content": content.toString()
    };
    final bool? response = await _channel.invokeMethod('copyToClipboard', args);
    return response;
  }

  static Future<bool?> shareOptions(String contentText,
      {String? imagePath}) async {
    Map<String, dynamic> args;
    if (Platform.isIOS) {
      args = <String, dynamic>{"image": imagePath, "content": contentText};
    } else {
      if (imagePath != null) {
        File file = File(imagePath);
        final bytes = file.readAsBytesSync();
        final tempDir = await getTemporaryDirectory();
        final imageName = 'stickerAsset.png';
        final imageDataPath = '${tempDir.path}/$imageName';
        final imageAsList = bytes.buffer.asUint8List();
        file = await File(imageDataPath).create();
        file.writeAsBytesSync(imageAsList);
        args = <String, dynamic>{"image": imageName, "content": contentText};
      } else {
        args = <String, dynamic>{"image": imagePath, "content": contentText};
      }
    }
    final bool? version = await _channel.invokeMethod('shareOptions', args);
    return version;
  }

  static Future<String?> shareWhatsapp(String content) async {
    final Map<String, dynamic> args = <String, dynamic>{"content": content};
    final String? version = await _channel.invokeMethod('shareWhatsapp', args);
    return version;
  }

  static Future<Map<String, bool>?> checkInstalledAppsForShare() async {
    final Map<String, bool>? apps =
        Map.from(await _channel.invokeMethod('checkInstalledApps'));
    return apps;
  }

  static Future<String?> shareTelegram(String content) async {
    final Map<String, dynamic> args = <String, dynamic>{"content": content};
    final String? version = await _channel.invokeMethod('shareTelegram', args);
    return version;
  }

// static Future<String> shareSlack() async {
//   final String version = await _channel.invokeMethod('shareSlack');
//   return version;
// }
}
