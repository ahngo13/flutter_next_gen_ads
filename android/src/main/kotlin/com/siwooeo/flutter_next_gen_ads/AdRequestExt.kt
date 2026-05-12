package com.siwooeo.flutter_next_gen_ads

import com.google.android.libraries.ads.mobile.sdk.common.AdRequest
import com.google.android.libraries.ads.mobile.sdk.common.BaseRequestBuilder
import com.google.android.libraries.ads.mobile.sdk.banner.BannerAdRequest
import com.google.android.libraries.ads.mobile.sdk.banner.AdSize

/**
 * Apply Dart-side targeting params (sent over the MethodChannel as a Map) to a
 * [BaseRequestBuilder]. Used by every Ad.load path so a single AdRequest shape
 * works for interstitial, rewarded, app open, and banner requests.
 */
@Suppress("UNCHECKED_CAST")
internal fun <T : BaseRequestBuilder<T>> Map<String, Any?>?.applyTargetingTo(
    builder: BaseRequestBuilder<T>,
) {
    val params = this ?: return
    (params["keywords"] as? List<*>)?.forEach {
        if (it is String) builder.addKeyword(it)
    }
    (params["customTargeting"] as? Map<*, *>)?.forEach { (k, v) ->
        if (k is String) {
            when (v) {
                is String -> builder.putCustomTargeting(k, v)
                is List<*> -> builder.putCustomTargeting(k, v.filterIsInstance<String>())
            }
        }
    }
    (params["contentUrl"] as? String)?.let { builder.setContentUrl(it) }
    (params["neighboringContentUrls"] as? List<*>)?.let { urls ->
        builder.setNeighboringContentUrls(urls.filterIsInstance<String>().toSet())
    }
    (params["requestAgent"] as? String)?.let { builder.setRequestAgent(it) }
    (params["categoryExclusions"] as? List<*>)?.forEach {
        if (it is String) builder.addCategoryExclusion(it)
    }
    (params["publisherProvidedId"] as? String)?.let { builder.setPublisherProvidedId(it) }
    (params["placementId"] as? Number)?.let { builder.setPlacementId(it.toLong()) }
}

/**
 * Build an [AdRequest] for a given ad unit ID with optional Dart-side
 * targeting params applied.
 */
internal fun buildAdRequest(adUnitId: String, params: Map<String, Any?>?): AdRequest {
    val builder = AdRequest.Builder(adUnitId)
    params.applyTargetingTo(builder)
    return builder.build()
}

/**
 * Build a [BannerAdRequest] for a given ad unit + size with optional Dart-side
 * targeting params applied.
 */
internal fun buildBannerAdRequest(
    adUnitId: String,
    size: AdSize,
    params: Map<String, Any?>?,
): BannerAdRequest {
    val builder = BannerAdRequest.Builder(adUnitId, size)
    params.applyTargetingTo(builder)
    return builder.build()
}
