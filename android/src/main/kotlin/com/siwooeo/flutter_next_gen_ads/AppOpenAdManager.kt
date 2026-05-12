package com.siwooeo.flutter_next_gen_ads

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.libraries.ads.mobile.sdk.appopen.AppOpenAd
import com.google.android.libraries.ads.mobile.sdk.appopen.AppOpenAdEventCallback
import com.google.android.libraries.ads.mobile.sdk.common.AdLoadCallback
import com.google.android.libraries.ads.mobile.sdk.common.FullScreenContentError
import com.google.android.libraries.ads.mobile.sdk.common.LoadAdError
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class AppOpenAdManager(private val channel: MethodChannel) {

    companion object {
        private const val TAG = "AppOpenAdManager"

        /** App open ads expire 4 hours after they are loaded. */
        private const val EXPIRY_MILLIS: Long = 4L * 60L * 60L * 1000L
    }

    private data class Entry(val ad: AppOpenAd, val loadedAt: Long)

    private val ads: MutableMap<String, Entry> = HashMap()
    private val mainHandler = Handler(Looper.getMainLooper())

    var activity: Activity? = null

    fun load(
        adUnitId: String,
        requestParams: Map<String, Any?>?,
        result: MethodChannel.Result,
    ) {
        val request = buildAdRequest(adUnitId, requestParams)
        AppOpenAd.load(
            request,
            object : AdLoadCallback<AppOpenAd> {
                override fun onAdLoaded(ad: AppOpenAd) {
                    val adId = UUID.randomUUID().toString()
                    ads[adId] = Entry(ad, System.currentTimeMillis())
                    attachEventCallbacks(adId, ad)
                    invokeOnMain {
                        result.success(mapOf("adId" to adId, "loaded" to true))
                    }
                }

                override fun onAdFailedToLoad(adError: LoadAdError) {
                    Log.w(TAG, "App open ad failed to load: $adError")
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
        val entry = ads[adId]
        val act = activity
        if (entry == null) {
            result.error("AD_NOT_FOUND", "No app open ad for id $adId", null)
            return
        }
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity unavailable to show app open ad.", null)
            return
        }
        if (isExpired(entry)) {
            ads.remove(adId)
            result.error("AD_EXPIRED", "App open ad expired (loaded > 4h ago).", null)
            return
        }
        entry.ad.show(act)
        result.success(null)
    }

    fun isAvailable(adId: String, result: MethodChannel.Result) {
        val entry = ads[adId]
        val available = entry != null && !isExpired(entry)
        if (entry != null && !available) {
            ads.remove(adId)
        }
        result.success(available)
    }

    fun dispose(adId: String) {
        val entry = ads.remove(adId) ?: return
        entry.ad.adEventCallback = null
    }

    private fun isExpired(entry: Entry): Boolean =
        System.currentTimeMillis() - entry.loadedAt >= EXPIRY_MILLIS

    private fun attachEventCallbacks(adId: String, ad: AppOpenAd) {
        ad.adEventCallback = object : AppOpenAdEventCallback {
            override fun onAdShowedFullScreenContent() {
                invokeOnMain { channel.invokeMethod("onAppOpenShowed", mapOf("adId" to adId)) }
            }

            override fun onAdDismissedFullScreenContent() {
                invokeOnMain { channel.invokeMethod("onAppOpenDismissed", mapOf("adId" to adId)) }
                ads.remove(adId)
            }

            override fun onAdFailedToShowFullScreenContent(error: FullScreenContentError) {
                invokeOnMain {
                    channel.invokeMethod(
                        "onAppOpenFailedToShow",
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
                invokeOnMain { channel.invokeMethod("onAppOpenImpression", mapOf("adId" to adId)) }
            }

            override fun onAdClicked() {
                invokeOnMain { channel.invokeMethod("onAppOpenClicked", mapOf("adId" to adId)) }
            }
        }
    }

    private fun invokeOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }
}
