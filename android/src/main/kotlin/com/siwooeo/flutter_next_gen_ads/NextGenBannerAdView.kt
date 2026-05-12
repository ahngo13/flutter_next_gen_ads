package com.siwooeo.flutter_next_gen_ads

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.google.android.libraries.ads.mobile.sdk.banner.AdSize
import com.google.android.libraries.ads.mobile.sdk.banner.AdView
import com.google.android.libraries.ads.mobile.sdk.banner.BannerAd
import com.google.android.libraries.ads.mobile.sdk.banner.BannerAdEventCallback
import com.google.android.libraries.ads.mobile.sdk.banner.BannerAdRefreshCallback
import com.google.android.libraries.ads.mobile.sdk.common.AdLoadCallback
import com.google.android.libraries.ads.mobile.sdk.common.FullScreenContentError
import com.google.android.libraries.ads.mobile.sdk.common.LoadAdError
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class NextGenBannerAdView(
    private val hostContext: Context,
    private val activity: Activity?,
    viewId: Int,
    messenger: BinaryMessenger,
    creationParams: Map<String, Any?>,
) : PlatformView {

    companion object {
        private const val TAG = "NextGenBannerAdView"
    }

    private val container: FrameLayout = FrameLayout(hostContext)
    private var adView: AdView? = null
    private val eventChannel = MethodChannel(messenger, "next_gen_sdk/banner_ad_$viewId")

    init {
        val adUnitId = creationParams["adUnitId"] as? String
        val widthDp = (creationParams["widthDp"] as? Number)?.toInt() ?: 360
        val sizeType = creationParams["sizeType"] as? String ?: "anchored"
        val maxHeightDp = (creationParams["maxHeightDp"] as? Number)?.toInt() ?: 0
        @Suppress("UNCHECKED_CAST")
        val requestParams = creationParams["request"] as? Map<String, Any?>

        when {
            adUnitId.isNullOrBlank() -> Log.e(TAG, "adUnitId is required.")
            activity == null -> Log.e(
                TAG,
                "BannerAdView requires an Activity. Make sure the plugin is " +
                    "attached to the host Activity before mounting the widget."
            )
            else -> {
                if (!NextGenAdsPlugin.isInitialized) {
                    Log.w(
                        TAG,
                        "MobileAds is not initialized. Call MobileAds.initialize() " +
                            "before creating a BannerAdView."
                    )
                }
                loadAd(adUnitId, widthDp, sizeType, maxHeightDp, requestParams, activity)
            }
        }
    }

    private fun loadAd(
        adUnitId: String,
        widthDp: Int,
        sizeType: String,
        maxHeightDp: Int,
        requestParams: Map<String, Any?>?,
        activity: Activity,
    ) {
        val adSize = resolveAdSize(activity, sizeType, widthDp, maxHeightDp)
        val request = buildBannerAdRequest(adUnitId, adSize, requestParams)
        val newAdView = AdView(activity)
        adView = newAdView
        container.addView(
            newAdView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
            )
        )

        newAdView.loadAd(
            request,
            object : AdLoadCallback<BannerAd> {
                override fun onAdLoaded(ad: BannerAd) {
                    Log.d(TAG, "Banner ad loaded.")
                    invokeOnMain("onAdLoaded", null)
                    ad.adEventCallback = object : BannerAdEventCallback {
                        override fun onAdImpression() {
                            invokeOnMain("onAdImpression", null)
                        }

                        override fun onAdClicked() {
                            invokeOnMain("onAdClicked", null)
                        }

                        override fun onAdShowedFullScreenContent() {
                            invokeOnMain("onAdShowedFullScreenContent", null)
                        }

                        override fun onAdDismissedFullScreenContent() {
                            invokeOnMain("onAdDismissedFullScreenContent", null)
                        }

                        override fun onAdFailedToShowFullScreenContent(
                            fullScreenContentError: FullScreenContentError
                        ) {
                            invokeOnMain(
                                "onAdFailedToShowFullScreenContent",
                                mapOf(
                                    "code" to fullScreenContentError.code,
                                    "message" to fullScreenContentError.message,
                                )
                            )
                        }
                    }
                    ad.bannerAdRefreshCallback = object : BannerAdRefreshCallback {
                        override fun onAdRefreshed() {
                            invokeOnMain("onAdRefreshed", null)
                        }

                        override fun onAdFailedToRefresh(loadAdError: LoadAdError) {
                            invokeOnMain(
                                "onAdFailedToRefresh",
                                mapOf(
                                    "code" to loadAdError.code,
                                    "message" to loadAdError.message,
                                )
                            )
                        }
                    }
                }

                override fun onAdFailedToLoad(adError: LoadAdError) {
                    Log.w(TAG, "Banner ad failed to load: $adError")
                    invokeOnMain(
                        "onAdFailedToLoad",
                        mapOf(
                            "code" to adError.code,
                            "message" to adError.message,
                        )
                    )
                }
            },
        )
    }

    private fun resolveAdSize(
        activity: Activity,
        sizeType: String,
        widthDp: Int,
        maxHeightDp: Int,
    ): AdSize {
        return when (sizeType) {
            "largeAnchored" -> AdSize.getLargeAnchoredAdaptiveBannerAdSize(activity, widthDp)
            "inline" -> AdSize.getInlineAdaptiveBannerAdSize(widthDp, maxHeightDp)
            else -> AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, widthDp)
        }
    }

    private fun invokeOnMain(method: String, args: Any?) {
        Handler(Looper.getMainLooper()).post {
            eventChannel.invokeMethod(method, args)
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        adView?.let { view ->
            (view.parent as? android.view.ViewGroup)?.removeView(view)
            view.destroy()
        }
        adView = null
        eventChannel.setMethodCallHandler(null)
    }
}
