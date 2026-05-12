package com.siwooeo.flutter_next_gen_ads

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import com.google.android.libraries.ads.mobile.sdk.MobileAds
import com.google.android.libraries.ads.mobile.sdk.initialization.InitializationConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class NextGenAdsPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "next_gen_sdk"
        const val BANNER_VIEW_TYPE = "next_gen_sdk/banner_ad"

        @Volatile
        var isInitialized: Boolean = false
            private set
    }

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private lateinit var interstitialManager: InterstitialAdManager
    private lateinit var rewardedInterstitialManager: RewardedInterstitialAdManager
    private lateinit var appOpenManager: AppOpenAdManager

    @Volatile
    private var hostActivity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        interstitialManager = InterstitialAdManager(channel)
        rewardedInterstitialManager = RewardedInterstitialAdManager(channel)
        appOpenManager = AppOpenAdManager(channel)

        binding.platformViewRegistry.registerViewFactory(
            BANNER_VIEW_TYPE,
            BannerAdViewFactory(binding.binaryMessenger) { hostActivity }
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        hostActivity = binding.activity
        interstitialManager.activity = binding.activity
        rewardedInterstitialManager.activity = binding.activity
        appOpenManager.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        hostActivity = null
        interstitialManager.activity = null
        rewardedInterstitialManager.activity = null
        appOpenManager.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        hostActivity = binding.activity
        interstitialManager.activity = binding.activity
        rewardedInterstitialManager.activity = binding.activity
        appOpenManager.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        hostActivity = null
        interstitialManager.activity = null
        rewardedInterstitialManager.activity = null
        appOpenManager.activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val argAppId = call.argument<String>("appId")
                val appId = argAppId?.takeIf { it.isNotBlank() } ?: readAppIdFromManifest()
                if (appId.isNullOrBlank()) {
                    result.error(
                        "MISSING_APP_ID",
                        "AdMob app ID not provided and not found in AndroidManifest.xml " +
                            "as <meta-data android:name=\"com.google.android.gms.ads.APPLICATION_ID\" .../>",
                        null
                    )
                    return
                }
                initializeSdk(appId, result)
            }

            "getVersion" -> {
                result.success(MobileAds.getVersion().toString())
            }

            "loadInterstitial" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adUnitId is required", null)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val req = call.argument<Map<String, Any?>>("request")
                interstitialManager.load(adUnitId, req, result)
            }

            "showInterstitial" -> {
                val adId = call.argument<String>("adId")
                if (adId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adId is required", null)
                    return
                }
                interstitialManager.show(adId, result)
            }

            "disposeInterstitial" -> {
                val adId = call.argument<String>("adId")
                if (!adId.isNullOrBlank()) interstitialManager.dispose(adId)
                result.success(null)
            }

            "loadRewardedInterstitial" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adUnitId is required", null)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val req = call.argument<Map<String, Any?>>("request")
                rewardedInterstitialManager.load(adUnitId, req, result)
            }

            "showRewardedInterstitial" -> {
                val adId = call.argument<String>("adId")
                if (adId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adId is required", null)
                    return
                }
                rewardedInterstitialManager.show(adId, result)
            }

            "disposeRewardedInterstitial" -> {
                val adId = call.argument<String>("adId")
                if (!adId.isNullOrBlank()) rewardedInterstitialManager.dispose(adId)
                result.success(null)
            }

            "loadAppOpen" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adUnitId is required", null)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val req = call.argument<Map<String, Any?>>("request")
                appOpenManager.load(adUnitId, req, result)
            }

            "setRequestConfiguration" -> {
                @Suppress("UNCHECKED_CAST")
                val config = call.argument<Map<String, Any?>>("config") ?: emptyMap()
                try {
                    applyRequestConfiguration(config)
                    result.success(null)
                } catch (t: Throwable) {
                    result.error("CONFIG_FAILED", t.message, null)
                }
            }

            "startInterstitialPreloader" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adUnitId is required", null)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val req = call.argument<Map<String, Any?>>("request")
                val buf = (call.argument<Number>("bufferSize"))?.toInt()
                result.success(PreloaderBridge.startInterstitial(adUnitId, req, buf))
            }

            "pollInterstitialPreloader" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adUnitId is required", null)
                    return
                }
                val ad = PreloaderBridge.pollInterstitial(adUnitId)
                if (ad == null) {
                    result.success(null)
                } else {
                    val adId = interstitialManager.adopt(ad)
                    result.success(mapOf("adId" to adId))
                }
            }

            "isInterstitialPreloaded" -> {
                val adUnitId = call.argument<String>("adUnitId") ?: ""
                result.success(PreloaderBridge.isInterstitialAvailable(adUnitId))
            }

            "interstitialPreloaderCount" -> {
                val adUnitId = call.argument<String>("adUnitId") ?: ""
                result.success(PreloaderBridge.interstitialCount(adUnitId))
            }

            "destroyInterstitialPreloader" -> {
                val adUnitId = call.argument<String>("adUnitId") ?: ""
                result.success(PreloaderBridge.destroyInterstitial(adUnitId))
            }

            "startRewardedPreloader" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adUnitId is required", null)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val req = call.argument<Map<String, Any?>>("request")
                val buf = (call.argument<Number>("bufferSize"))?.toInt()
                result.success(PreloaderBridge.startRewarded(adUnitId, req, buf))
            }

            "pollRewardedPreloader" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adUnitId is required", null)
                    return
                }
                val ad = PreloaderBridge.pollRewarded(adUnitId)
                if (ad == null) {
                    result.success(null)
                } else {
                    val adId = rewardedInterstitialManager.adopt(ad)
                    result.success(mapOf("adId" to adId))
                }
            }

            "isRewardedPreloaded" -> {
                val adUnitId = call.argument<String>("adUnitId") ?: ""
                result.success(PreloaderBridge.isRewardedAvailable(adUnitId))
            }

            "rewardedPreloaderCount" -> {
                val adUnitId = call.argument<String>("adUnitId") ?: ""
                result.success(PreloaderBridge.rewardedCount(adUnitId))
            }

            "destroyRewardedPreloader" -> {
                val adUnitId = call.argument<String>("adUnitId") ?: ""
                result.success(PreloaderBridge.destroyRewarded(adUnitId))
            }

            "showAppOpen" -> {
                val adId = call.argument<String>("adId")
                if (adId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "adId is required", null)
                    return
                }
                appOpenManager.show(adId, result)
            }

            "isAppOpenAvailable" -> {
                val adId = call.argument<String>("adId")
                if (adId.isNullOrBlank()) {
                    result.success(false)
                    return
                }
                appOpenManager.isAvailable(adId, result)
            }

            "disposeAppOpen" -> {
                val adId = call.argument<String>("adId")
                if (!adId.isNullOrBlank()) appOpenManager.dispose(adId)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun readAppIdFromManifest(): String? {
        return try {
            val info = appContext.packageManager.getApplicationInfo(
                appContext.packageName,
                PackageManager.GET_META_DATA,
            )
            info.metaData?.getString("com.google.android.gms.ads.APPLICATION_ID")
        } catch (t: Throwable) {
            null
        }
    }

    private fun initializeSdk(appId: String, result: MethodChannel.Result) {
        val scope = CoroutineScope(Dispatchers.IO)
        scope.launch {
            try {
                MobileAds.initialize(
                    appContext,
                    InitializationConfig.Builder(appId).build()
                ) {
                    isInitialized = true
                    result.success(mapOf("isReady" to true))
                }
            } catch (t: Throwable) {
                result.error("INIT_FAILED", t.message, null)
            }
        }
    }
}
