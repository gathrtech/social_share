import Flutter
import UIKit
import UniformTypeIdentifiers
import Social
import MessageUI

public let ShareToInstagramNotifiction: Notification.Name = .init(rawValue: "ShareToInstagramNotification")

public class SwiftSocialSharePlugin: NSObject, FlutterPlugin, MFMessageComposeViewControllerDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "social_share", binaryMessenger: registrar.messenger())
    let instance = SwiftSocialSharePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

    switch call.method {
    case "shareInstagramStory":
        shareInstagramStory(call, result: result)
    case "shareFacebookStory":
        shareFacebookStory(call, result: result)
    case "copyToClipboard":
        copyToClipboard(call, result: result)
    case "shareTwitter":
        shareTwitter(call, result: result)
    case "shareSms":
        shareSms(call, result: result)
    case "shareWhatsapp":
        shareWhatsapp(call, result: result)
    case "shareTelegram":
        shareTelegram(call, result: result)
    case "shareOptions":
        shareOptions(call, result: result)
    case "checkInstalledApps":
        checkInstalledApps(call, result: result)
    default:
        result(FlutterMethodNotImplemented)
    }
  }
    
    func shareOptions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result("call arguments not valid")
            return
        }
        
        var content: [Any] = []
        
        guard
            let message = arguments["message"] as? String
        else {
            result("Missing required message parameter")
            return
        }
        
        content.append(message)
        
        if let imageFile = arguments["image"] as? String, let uiImage = UIImage(contentsOfFile: imageFile) {
            content.append(uiImage)
        }
        
        guard let viewController = getTopViewController() else {
            result("Could not load root view controller")
            return
        }
        
        let activityController = UIActivityViewController(activityItems: content, applicationActivities: nil)

        DispatchQueue.main.async {
            viewController.present(activityController, animated: true)
            result(true)
        }
        
    }

    func shareWhatsapp(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result("call arguments not valid")
            return
        }

        guard
            let message = arguments["message"] as? String,
            let formatted = message.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let urlScheme = URL(string: "whatsapp://send?text=\(formatted)")
        else {
            result("message not provided")
            return
        }
                
        if UIApplication.shared.canOpenURL(urlScheme) {
            if #available(iOS 10, *) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(urlScheme)
                    result("sharing")
                }
            }
            
        } else {
            result("Cant share to whatsapp")
        }
    }
    
    func shareTelegram(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result("call arguments not valid")
            return
        }

        guard
            let message = arguments["message"] as? String,
            let formatted = message.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let urlScheme = URL(string: "tg://msg?text=\(formatted)")
        else {
            result("message not provided")
            return
        }
                
        if UIApplication.shared.canOpenURL(urlScheme) {
            if #available(iOS 10, *) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(urlScheme)
                    result("sharing")
                }
            }
            
        } else {
            result("Cant share to telegram")
        }
    }
    
    func shareSms(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result("call arguments not valid")
            return
        }

        guard let message = arguments["message"] as? String else {
            result("message not provided")
            return
        }
        
        let urlScheme = URL(string: "sms://")!
        
        if UIApplication.shared.canOpenURL(urlScheme) {
            
            guard let viewController = getTopViewController() else {
                result("Could not load root view controller")
                return
            }
            
            let messageVc = MFMessageComposeViewController()
            
            messageVc.body = message
            messageVc.messageComposeDelegate = self
            
            if let imageFile = arguments["image"] as? String, let uiImage = UIImage(contentsOfFile: imageFile), let imageData = uiImage.jpegData(compressionQuality: 1.0) {
                messageVc.addAttachmentData(imageData, typeIdentifier: "image/jpeg", filename: "image.jpeg")
            }
            
            DispatchQueue.main.async {
                viewController.present(messageVc, animated: true)
                result("sharing")
            }
            
        } else {
            result("Cant share to SMS")
        }
    }
    
    func shareTwitter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result("call arguments not valid")
            return
        }
        
        let urlScheme = URL(string: "twitter://")!
        
        if UIApplication.shared.canOpenURL(urlScheme) {
            let outputText: String
            switch (arguments["captionText"] as? String, arguments["trailingText"] as? String) {
            case let (caption?, trailing?):
                outputText = "\(caption) \(trailing)"
            case let (caption?, _):
                outputText = "\(caption)"
            case let (_, trailing?):
                outputText = "\(trailing)"
            default:
                result("Missing caption or trailing text")
                return
            }
            
            let trimmed = outputText.trimmingCharacters(in: CharacterSet.whitespaces)
            
            let url: URL?
            if let urlString = arguments["url"] as? String {
                url = URL(string: urlString)
            } else {
                url = nil
            }
            
            let twitterVc = SLComposeViewController(forServiceType: SLServiceTypeTwitter)!
            twitterVc.add(url)
            
            if trimmed.count > 0 {
                twitterVc.setInitialText(trimmed)
            }
            
            guard let viewController = getTopViewController() else {
                result("Could not load root view controller")
                return
            }
            
            viewController.present(twitterVc, animated: true)
            result("sharing")
        } else {
            result("Can't open twitter")
        }
    }
    
    func copyToClipboard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result("call arguments not valid")
            return;
        }
        
        guard let content = arguments["content"] as? String else {
            result("No content to copy to clipboard")
            return;
        }
        
        UIPasteboard.general.string = content
        result(true)
    }
    
    func shareFacebookStory(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        guard let arguments = call.arguments as? [String: Any] else {
            result("call arguments not valid")
            return;
        }
        
        var sticker: UIImage?
        if let stickerImage = arguments["stickerImage"] as? String {
            if FileManager.default.fileExists(atPath: stickerImage) {
                sticker = UIImage(contentsOfFile: stickerImage)
            }
        }
        
        var background: UIImage?
        if let backgroundImage = arguments["backgroundImage"] as? String {
            if FileManager.default.fileExists(atPath: backgroundImage) {
                background = UIImage(contentsOfFile: backgroundImage)
            }
        }
        
        guard let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),let plistXml = FileManager.default.contents(atPath: infoPlistPath), let infoPlist = try? PropertyListDecoder().decode(InfoPlistData.self, from: plistXml)  else {
            result("Could not load info plist")
            return;
        }
        
        let storiesUrl = URL(string: "facebook-stories://share")!
        
        if UIApplication.shared.canOpenURL(storiesUrl) {
            
            var pasteboardItems: [String: Any] = [
                "com.facebook.sharedSticker.appID": infoPlist.facebookAppID,
            ]
            
            if let sticker = sticker {
                pasteboardItems["com.facebook.sharedSticker.stickerImage"] = sticker
            }

            
            if let background = background {
                pasteboardItems["com.facebook.sharedSticker.backgroundImage"] = background
            }
            
            if let backgroundTopColor = arguments["backgroundTopColor"] as? String {
                pasteboardItems["com.facebook.sharedSticker.backgroundTopColor"] = backgroundTopColor
            }
            
            if let backgroundBottomColor = arguments["backgroundBottomColor"] as? String {
                pasteboardItems["com.facebook.sharedSticker.backgroundBottomColor"] = backgroundBottomColor
            }
            
            if let attributionURL = arguments["attributionURL"] as? String {
                pasteboardItems["com.facebook.sharedSticker.contentURL"] = attributionURL
            }
            
            
            if let linkToCopy = arguments["linkToCopy"] as? String {
                pasteboardItems["public.url"] = linkToCopy
                pasteboardItems["public.text"] = linkToCopy
            }
            
            if #available(iOS 10, *) {
                
                let opts = [
                    UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60 * 5)
                ]
                
                UIPasteboard.general.setItems([pasteboardItems], options: opts)
                                
                UIApplication.shared.open(storiesUrl) { _ in
                    let id = UIApplication.shared.beginBackgroundTask()
                    
                    sleep(2)

                    if  let cp = UIPasteboard(name: UIPasteboard.Name.general, create: false),
                        let linkToCopy = arguments["linkToCopy"] as? String {
                        cp.setValue(linkToCopy, forPasteboardType: "public.url")
                    }
                    
                    UIApplication.shared.endBackgroundTask(id)
                }
                
                result("sharing")
            } else {
                result("this only supports iOS 10+")
            }
        } else {
            result("not supported or no facebook installed")
        }
    }
    
    func shareInstagramStory(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        guard let arguments = call.arguments as? [String: Any] else {
            result("call arguments not valid")
            return;
        }
                
        var sticker: UIImage?
        if let stickerImage = arguments["stickerImage"] as? String {
            if FileManager.default.fileExists(atPath: stickerImage) {
                sticker = UIImage(contentsOfFile: stickerImage)
            }
        }
        
        var background: UIImage?
        if let backgroundImage = arguments["backgroundImage"] as? String {
            if FileManager.default.fileExists(atPath: backgroundImage) {
                background = UIImage(contentsOfFile: backgroundImage)
            }
        }
        
        let storiesUrl = URL(string: "instagram-stories://share")!

        if UIApplication.shared.canOpenURL(storiesUrl) {
                        
            var pasteboardItems = [String: Any]()
            
            if let sticker = sticker {
                pasteboardItems["com.instagram.sharedSticker.stickerImage"] = sticker
            }

            
            if let background = background {
                pasteboardItems["com.instagram.sharedSticker.backgroundImage"] = background
            }
            
            if let backgroundTopColor = arguments["backgroundTopColor"] as? String {
                pasteboardItems["com.instagram.sharedSticker.backgroundTopColor"] = backgroundTopColor
            }
            
            if let backgroundBottomColor = arguments["backgroundBottomColor"] as? String {
                pasteboardItems["com.instagram.sharedSticker.backgroundBottomColor"] = backgroundBottomColor
            }
            
            if let attributionURL = arguments["attributionURL"] as? String {
                pasteboardItems["com.instagram.sharedSticker.contentURL"] = attributionURL
            }

            
            if #available(iOS 10, *) {
                
                let opts = [
                    UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60 * 5)
                ]
                
                UIPasteboard.general.setItems([pasteboardItems], options: opts)
                                
                UIApplication.shared.open(storiesUrl) { _ in
                    let id = UIApplication.shared.beginBackgroundTask()
                    
                    sleep(2)

                    if  let cp = UIPasteboard(name: UIPasteboard.Name.general, create: false),
                        let linkToCopy = arguments["linkToCopy"] as? String {
                        cp.setValue(linkToCopy, forPasteboardType: "public.url")
                    }
                    
                    UIApplication.shared.endBackgroundTask(id)
                }
                
                result("sharing")
            } else {
                result("this only supports iOS 10+")
            }
        } else {
            result("not supported or no instagram installed")
        }
    }
    
    func getTopViewController() -> UIViewController? {
        if #available(iOS 13, *) {
            guard let window = UIApplication.shared.connectedScenes
                .filter({scene in
                    scene.activationState == .foregroundActive
                })
                    .first(where: { $0 is UIWindowScene })
                .flatMap({ $0 as? UIWindowScene })?.windows.first(where: \.isKeyWindow)  else {
                return nil
                }
                
                guard let rootController = window.rootViewController else {
                    return nil
                }
            
            return rootController
        } else {
            guard let window = UIApplication.shared.keyWindow, let rootViewController = window.rootViewController else {
                return nil

            }
            return rootViewController
        }
    }
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
    
    func checkInstalledApps(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let installedApps = [
            "instagram": UIApplication.shared.canOpenURL(URL(string: "instagram-stories://")!),
            "facebook": UIApplication.shared.canOpenURL(URL(string: "facebook-stories://")!),
            "twitter": UIApplication.shared.canOpenURL(URL(string: "twitter://")!),
            "sms": UIApplication.shared.canOpenURL(URL(string: "sms://")!),
            "whatsapp": UIApplication.shared.canOpenURL(URL(string: "whatsapp://")!),
            "telegram": UIApplication.shared.canOpenURL(URL(string: "tg://")!),
        ]
        
        result(installedApps)
    }
}

struct InfoPlistData: Codable {
    let facebookAppID: String
    
    enum CodingKeys: String, CodingKey {
        case facebookAppID = "FacebookAppID"
    }
}
