package com.siwooeo.flutter_next_gen_ads

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.libraries.ads.mobile.sdk.common.AdLoadCallback
import com.google.android.libraries.ads.mobile.sdk.common.FullScreenContentError
import com.google.android.libraries.ads.mobile.sdk.common.LoadAdError
import com.google.android.libraries.ads.mobile.sdk.interstitial.InterstitialAd
import com.google.android.libraries.ads.mobile.sdk.interstitial.InterstitialAdEventCallback
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class InterstitialAdManager(private val channel: MethodChannel) {

    companion object {
        private const val TAG = "InterstitialAdManager"
    }

    private val ads: MutableMap<String, InterstitialAd> = HashMap()
    private val mainHandler = Handler(Looper.getMainLooper())

    var activity: Activity? = null

    fun load(
        adUnitId: String,
        requestParams: Map<String, Any?>?,
        result: MethodChannel.Result,
    ) {
        val request = buildAdRequest(adUnitId, requestParams)
        InterstitialAd.load(
            request,
            object : AdLoadCallback<InterstitialAd> {
                override fun onAdLoaded(ad: InterstitialAd) {
                    val adId = UUID.randomUUID().toString()
                    ads[adId] = ad
                    attachEventCallbacks(adId, ad)
                    invokeOnMain {
                        result.success(mapOf("adId" to adId, "loaded" to true))
                    }
                }

                override fun onAdFailedToLoad(adError: LoadAdError) {
                    Log.w(TAG, "Interstitial failed to load: $adError")
                    invokeOnMain {
                        result.success(
                            mapOf(
                                "loaded" to false,
                                "error" to mapOf(
                                    "code" to adError.code,
                                    "message" to adError.message,
                                )
                            )
                        )
                    }
                }
            },
        )
    }

    fun show(adId: String, result: MethodChannel.Result) {
        val ad = ads[adId]
        val act = activity
        if (ad == null) {
            result.error("AD_NOT_FOUND", "No interstitial ad found for id $adId", null)
            return
        }
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is not available to show interstitial.", null)
            return
        }
        ad.show(act)
        result.success(null)
    }

    fun dispose(adId: String) {
        val ad = ads.remove(adId) ?: return
        // Clearing the callback prevents stale references.
        ad.adEventCallback = null
    }

    /**
     * Adopt a pre-loaded [InterstitialAd] (e.g. from [PreloaderBridge]) so it
     * can be shown via [show] using the returned adId.
     */
    fun adopt(ad: InterstitialAd): String {
        val adId = java.util.UUID.randomUUID().toString()
        ads[adId] = ad
        attachEventCallbacks(adId, ad)
        return adId
    }

    private fun attachEventCallbacks(adId: String, ad: InterstitialAd) {
        ad.adEventCallback = object : InterstitialAdEventCallback {
            override fun onAdShowedFullScreenContent() {
                invokeOnMain { channel.invokeMethod("onInterstitialShowed", mapOf("adId" to adId)) }
            }

            override fun onAdDismissedFullScreenContent() {
                invokeOnMain { channel.invokeMethod("onInterstitialDismissed", mapOf("adId" to adId)) }
                ads.remove(adId)
            }

            override fun onAdFailedToShowFullScreenContent(error: FullScreenContentError) {
                invokeOnMain {
                    channel.invokeMethod(
                        "onInterstitialFailedToShow",
                        mapOf(
                            "adId" to adId,
                            "code" to error.code,
                            "message" to error.message,
                        )
                    )
                }
                ads.remove(adId)
            }

            override fun onAdImpression() {
                invokeOnMain { channel.invokeMethod("onInterstitialImpression", mapOf("adId" to adId)) }
            }

            override fun onAdClicked() {
                invokeOnMain { channel.invokeMethod("onInterstitialClicked", mapOf("adId" to adId)) }
            }
        }
    }

    private fun invokeOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }
}
