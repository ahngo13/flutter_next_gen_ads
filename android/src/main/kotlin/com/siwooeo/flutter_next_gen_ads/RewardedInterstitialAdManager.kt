package com.siwooeo.flutter_next_gen_ads

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.libraries.ads.mobile.sdk.common.AdLoadCallback
import com.google.android.libraries.ads.mobile.sdk.common.FullScreenContentError
import com.google.android.libraries.ads.mobile.sdk.common.LoadAdError
import com.google.android.libraries.ads.mobile.sdk.rewarded.OnUserEarnedRewardListener
import com.google.android.libraries.ads.mobile.sdk.rewarded.RewardItem
import com.google.android.libraries.ads.mobile.sdk.rewardedinterstitial.RewardedInterstitialAd
import com.google.android.libraries.ads.mobile.sdk.rewardedinterstitial.RewardedInterstitialAdEventCallback
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class RewardedInterstitialAdManager(private val channel: MethodChannel) {

    companion object {
        private const val TAG = "RewardedInterstitial"
    }

    private val ads: MutableMap<String, RewardedInterstitialAd> = HashMap()
    private val mainHandler = Handler(Looper.getMainLooper())

    var activity: Activity? = null

    fun load(
        adUnitId: String,
        requestParams: Map<String, Any?>?,
        result: MethodChannel.Result,
    ) {
        val request = buildAdRequest(adUnitId, requestParams)
        RewardedInterstitialAd.load(
            request,
            object : AdLoadCallback<RewardedInterstitialAd> {
                override fun onAdLoaded(ad: RewardedInterstitialAd) {
                    val adId = UUID.randomUUID().toString()
                    ads[adId] = ad
                    attachEventCallbacks(adId, ad)
                    invokeOnMain {
                        result.success(mapOf("adId" to adId, "loaded" to true))
                    }
                }

                override fun onAdFailedToLoad(adError: LoadAdError) {
                    Log.w(TAG, "Rewarded interstitial failed to load: $adError")
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
            result.error("AD_NOT_FOUND", "No rewarded interstitial ad for id $adId", null)
            return
        }
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is not available to show rewarded ad.", null)
            return
        }
        ad.show(
            act,
            object : OnUserEarnedRewardListener {
                override fun onUserEarnedReward(rewardItem: RewardItem) {
                    invokeOnMain {
                        channel.invokeMethod(
                            "onUserEarnedReward",
                            mapOf(
                                "adId" to adId,
                                "amount" to rewardItem.amount,
                                "type" to rewardItem.type,
                            )
                        )
                    }
                }
            },
        )
        result.success(null)
    }

    fun dispose(adId: String) {
        val ad = ads.remove(adId) ?: return
        ad.adEventCallback = null
    }

    /**
     * Adopt a pre-loaded [RewardedInterstitialAd] (e.g. from [PreloaderBridge])
     * so it can be shown via [show] using the returned adId.
     */
    fun adopt(ad: RewardedInterstitialAd): String {
        val adId = java.util.UUID.randomUUID().toString()
        ads[adId] = ad
        attachEventCallbacks(adId, ad)
        return adId
    }

    private fun attachEventCallbacks(adId: String, ad: RewardedInterstitialAd) {
        ad.adEventCallback = object : RewardedInterstitialAdEventCallback {
            override fun onAdShowedFullScreenContent() {
                invokeOnMain { channel.invokeMethod("onRewardedShowed", mapOf("adId" to adId)) }
            }

            override fun onAdDismissedFullScreenContent() {
                invokeOnMain { channel.invokeMethod("onRewardedDismissed", mapOf("adId" to adId)) }
                ads.remove(adId)
            }

            override fun onAdFailedToShowFullScreenContent(error: FullScreenContentError) {
                invokeOnMain {
                    channel.invokeMethod(
                        "onRewardedFailedToShow",
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
                invokeOnMain { channel.invokeMethod("onRewardedImpression", mapOf("adId" to adId)) }
            }

            override fun onAdClicked() {
                invokeOnMain { channel.invokeMethod("onRewardedClicked", mapOf("adId" to adId)) }
            }
        }
    }

    private fun invokeOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }
}
