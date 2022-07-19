package com.shekarmudaliyar.social_share

import android.app.Activity
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import androidx.core.content.FileProvider
import com.snap.creativekit.SnapCreative
import com.snap.creativekit.api.SnapCreativeKitCompletionCallback
import com.snap.creativekit.api.SnapCreativeKitSendError
import com.snap.creativekit.exceptions.SnapStickerSizeException
import com.snap.creativekit.models.SnapContent
import com.snap.creativekit.models.SnapLiveCameraContent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class SocialSharePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var activeContext: Context? = null
    private var context: Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "social_share")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        activeContext = if (activity != null) activity!!.applicationContext else context!!

        when (call.method) {
            "shareInstagramStory" -> {
                //share on instagram story
                onShareInstagramStory(call, result)
            }
            "shareFacebookStory" -> {
                //share on facebook story
                onShareFacebookStory(call, result)
            }
            "shareOptions" -> {
                onShareOptions(call, result)
            }
            "copyToClipboard" -> {
                //copies content onto the clipboard
                onCopyClipboard(call, result)
            }
            "shareWhatsapp" -> {
                onShareWhatsApp(call, result)
            }
            "shareSms" -> {
                //shares content on sms
                onShareSms(call, result)
            }
            "shareTwitter" -> {
                //shares content on twitter
                onShareTwitter(call, result)
            }
            "shareTelegram" -> {
                //shares content on Telegram
                onShareTelegram(call, result)
            }
            "checkInstalledApps" -> {
                checkInstalledApps(result)
            }
            "shareSnapchat" -> {
                shareSnapchat(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkInstalledApps(result: Result) {
        //check if the apps exists
        //creating a mutable map of apps
        val apps: MutableMap<String, Boolean> = mutableMapOf()
        //assigning package manager
        val pm: PackageManager = context!!.packageManager
        //get a list of installed apps.
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        //intent to check sms app exists
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("sms:")
        }

        val smsActive = intent.resolveActivity(activity!!.packageManager) != null

        //if sms app exists
        apps["sms"] = smsActive
        //if other app exists
        apps["instagram"] =
            packages.any { it.packageName.toString().contentEquals("com.instagram.android") }
        apps["facebook"] =
            packages.any { it.packageName.toString().contentEquals("com.facebook.katana") }
        apps["twitter"] =
            packages.any { it.packageName.toString().contentEquals("com.twitter.android") }
        apps["whatsapp"] = packages.any { it.packageName.toString().contentEquals("com.whatsapp") }
        apps["telegram"] =
            packages.any { it.packageName.toString().contentEquals("org.telegram.messenger") }
        apps["snapchat"] = packages.any { it.packageName.toString().contentEquals("com.snapchat.android") }

        result.success(apps)
    }

    private fun shareSnapchat(
        call: MethodCall,
        result: Result
    ) {
        val snapCreativeKitApi = SnapCreative.getApi(activeContext!!)

        val snapMediaFactory = SnapCreative.getMediaFactory(activeContext!!)

        val snapContent: SnapContent = SnapLiveCameraContent()

        val stickerUrl: String? = call.argument("sticker")

        if (stickerUrl != null) {
            val imageFile =  File(activeContext!!.cacheDir, stickerUrl)
            val imageUri = Uri.parse(imageFile.path);
            try {
                val snapSticker = snapMediaFactory.getSnapStickerFromFile(imageFile)
                snapSticker.setHeightDp(200f)
                snapSticker.setWidthDp(150f)
                activity!!.grantUriPermission("com.snapchat.android", imageUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                snapContent.snapSticker = snapSticker
            } catch (e: SnapStickerSizeException) {
                println(e.toString())
                result.error("1", "Could not load file", null)
            }
        }

        call.argument<String>("caption")?.let {
            snapContent.captionText = it
        }

        call.argument<String>("urlLink")?.let {
            snapContent.attachmentUrl = it
        }

        snapCreativeKitApi.sendWithCompletionHandler(snapContent, object: SnapCreativeKitCompletionCallback {
            override fun onSendSuccess() {
                println("Send Success!")
                result.success("true")
            }

            override fun onSendFailed(p0: SnapCreativeKitSendError?) {
                println("Snapchat Send Failure! $p0")
                result.success("false")
            }
        })
    }

    private fun onShareTelegram(
        call: MethodCall,
        result: Result
    ) {
        val content: String? = call.argument("content")
        val telegramIntent = Intent(Intent.ACTION_SEND)
        telegramIntent.type = "text/plain"
        telegramIntent.setPackage("org.telegram.messenger")
        telegramIntent.putExtra(Intent.EXTRA_TEXT, content)
        try {
            activity!!.startActivity(telegramIntent)
            result.success("true")
        } catch (ex: ActivityNotFoundException) {
            result.success("false")
        }
    }

    private fun onShareTwitter(
        call: MethodCall,
        result: Result
    ) {

        val text: String = call.argument("captionText") ?: ""
        val url: String = call.argument("url") ?: ""
        val trailingText: String = call.argument("trailingText") ?: ""

        val appIntent = Intent(Intent.ACTION_SEND)
        appIntent.setPackage("com.twitter.android")
        appIntent.type = "text/plain"
        appIntent.putExtra(Intent.EXTRA_TEXT, "$text$url$trailingText")

        try {
            activity!!.startActivity(appIntent)
            result.success("true")
        } catch (ex: ActivityNotFoundException) {
            val urlScheme = "http://www.twitter.com/intent/tweet?text=$text$url$trailingText"
            Log.d("log", urlScheme)
            val intent = Intent(Intent.ACTION_VIEW)
            intent.data = Uri.parse(urlScheme)
            try {
                activity!!.startActivity(intent)
                result.success("true")
            } catch (ex: ActivityNotFoundException) {
                result.success("false")
            }
        }
    }

    private fun onShareSms(@NonNull call: MethodCall, @NonNull result: Result) {
        val content: String? = call.argument("message")
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("sms:")
            putExtra("sms_body", content)
        }

        try {
            activity!!.startActivity(intent)
            result.success("true")
        } catch (ex: ActivityNotFoundException) {
            result.success("false")
        }
    }

    private fun onShareWhatsApp(@NonNull call: MethodCall, @NonNull result: Result) {
        val content: String? = call.argument("content")
        val whatsappIntent = Intent(Intent.ACTION_SEND)
        whatsappIntent.type = "text/plain"
        whatsappIntent.setPackage("com.whatsapp")
        whatsappIntent.putExtra(Intent.EXTRA_TEXT, content)

        try {
            activity!!.startActivity(whatsappIntent)
            result.success("true")
        } catch (ex: ActivityNotFoundException) {
            result.success("false")
        }
    }

    private fun onCopyClipboard(@NonNull call: MethodCall, @NonNull result: Result) {
        val content: String? = call.argument("content")
        var clipboard = context!!.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

        val clip = ClipData.newPlainText("", content)
        clipboard.setPrimaryClip(clip)
        result.success(true)
    }

    private fun onShareOptions(@NonNull call: MethodCall, @NonNull result: Result) {
        //native share options
        val image: String? = call.argument("image")
        val intent = Intent()
        intent.action = Intent.ACTION_SEND

        if (image != null) {
            //check if  image is also provided
            val imageFile =  File(activeContext!!.cacheDir,image)
            val imageFileUri = FileProvider.getUriForFile(activeContext!!, activeContext!!.applicationContext.packageName + ".fileprovider", imageFile)
            intent.type = "image/*"
            intent.putExtra(Intent.EXTRA_STREAM,imageFileUri)
        } else {
            intent.type = "text/plain"
        }

        call.argument<String>("content")?.let {
            intent.putExtra(Intent.EXTRA_TEXT, it)
        }

        //create chooser intent to launch intent
        //source: "share" package by flutter (https://github.com/flutter/plugins/blob/master/packages/share/)
        val chooserIntent: Intent = Intent.createChooser(intent, null /* dialog title optional */)
        chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        activeContext!!.startActivity(chooserIntent)
        result.success(true)

    }

    private fun onShareInstagramStory(@NonNull call: MethodCall, @NonNull result: Result) {
        val intent = Intent("com.instagram.share.ADD_TO_STORY")
        intent.type = "image/*"
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.putExtra("source_application", activeContext!!.applicationContext.packageName)

        call.argument<String>("backgroundImage")?.let {
            val backfile =  File(activeContext!!.cacheDir, it)
            val backgroundImageFile = FileProvider.getUriForFile(activeContext!!, activeContext!!.applicationContext.packageName + ".fileprovider", backfile)
            intent.setDataAndType(backgroundImageFile,"image/*")
        }

        call.argument<String>("backgroundVideoPath")?.let {
            val file = File(activeContext!!.cacheDir, it)
            val backgroundVideoFile = FileProvider.getUriForFile(activeContext!!, activeContext!!.applicationContext.packageName + ".fileprovider", file)
            intent.setDataAndType(backgroundVideoFile, "video/*")
        }

        call.argument<String>("backgroundTopColor")?.let {
            intent.putExtra("top_background_color", it)
        }

        call.argument<String>("backgroundBottomColor")?.let {
            intent.putExtra("bottom_background_color", it)
        }

        call.argument<String>("attributionURL")?.let {
            intent.putExtra("content_url", it)
        }

        call.argument<String>("stickerImage")?.let {
            val stickerFile = File(activeContext!!.cacheDir, it)
            val stickerFilePath = FileProvider.getUriForFile(activeContext!!, activeContext!!.applicationContext.packageName + ".fileprovider", stickerFile)
            intent.putExtra("interactive_asset_uri", stickerFilePath)
            activity!!.grantUriPermission("com.instagram.android", stickerFilePath, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        
        Log.d("", activity!!.toString())

        call.argument<String>("linkToCopy")?.let {
            var clipboard = context!!.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("", it)
            clipboard.setPrimaryClip(clip)
        }

        if (activity!!.packageManager.resolveActivity(intent, 0) != null) {
            activeContext!!.startActivity(intent)
            result.success("success")
        } else {
            result.success("error")
        }
    }

    private fun onShareFacebookStory(@NonNull call: MethodCall, @NonNull result: Result) {
        val stickerImage: String? = call.argument("stickerImage")
        val appId: String? = call.argument("appId")
        val file =  File(activeContext!!.cacheDir,stickerImage)
        val stickerImageFile = FileProvider.getUriForFile(activeContext!!, activeContext!!.applicationContext.packageName + ".fileprovider", file)

        val intent = Intent("com.facebook.stories.ADD_TO_STORY")
        intent.type = "image/*"
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)

        intent.putExtra("interactive_asset_uri", stickerImageFile)

        call.argument<String>("backgroundImage")?.let {
            val backfile =  File(activeContext!!.cacheDir, it)
            val backgroundImageFile = FileProvider.getUriForFile(activeContext!!, activeContext!!.applicationContext.packageName + ".fileprovider", backfile)
            intent.setDataAndType(backgroundImageFile,"image/*")
        }

        call.argument<String>("backgroundVideoPath")?.let {
            val file = File(activeContext!!.cacheDir, it)
            val backgroundVideoFile = FileProvider.getUriForFile(activeContext!!, activeContext!!.applicationContext.packageName + ".fileprovider", file)
            intent.setDataAndType(backgroundVideoFile, "video/*")
        }

        call.argument<String>("backgroundTopColor")?.let {
            intent.putExtra("top_background_color", it)
        }

        call.argument<String>("backgroundBottomColor")?.let {
            intent.putExtra("bottom_background_color", it)
        }

        call.argument<String>("attributionURL")?.let {
            intent.putExtra("content_url", it)
        }

        call.argument<String>("stickerImage")?.let {
            val backfile = File(activeContext!!.cacheDir, it)
            val backgroundImageFile = FileProvider.getUriForFile(activeContext!!, activeContext!!.applicationContext.packageName + ".fileprovider", backfile)
            intent.putExtra("interactive_asset_uri", backgroundImageFile)
        }

        call.argument<String>("linkToCopy")?.let {
            var clipboard = context!!.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("", it)
            clipboard.setPrimaryClip(clip)
        }

        Log.d("", activity!!.toString())

        // Instantiate activity and verify it will resolve implicit intent
        activity!!.grantUriPermission("com.facebook.katana", stickerImageFile, Intent.FLAG_GRANT_READ_URI_PERMISSION)

        if (activity!!.packageManager.resolveActivity(intent, 0) != null) {
            activeContext!!.startActivity(intent)
            result.success("success")
        } else {
            result.success("error")
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.getActivity()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
