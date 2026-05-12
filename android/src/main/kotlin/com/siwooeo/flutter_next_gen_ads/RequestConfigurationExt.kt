package com.siwooeo.flutter_next_gen_ads

import com.google.android.libraries.ads.mobile.sdk.MobileAds
import com.google.android.libraries.ads.mobile.sdk.common.RequestConfiguration
import com.google.android.libraries.ads.mobile.sdk.common.RequestConfiguration.MaxAdContentRating
import com.google.android.libraries.ads.mobile.sdk.common.RequestConfiguration.PublisherPrivacyPersonalizationState
import com.google.android.libraries.ads.mobile.sdk.common.RequestConfiguration.TagForChildDirectedTreatment
import com.google.android.libraries.ads.mobile.sdk.common.RequestConfiguration.TagForUnderAgeOfConsent

/** Apply Dart-side RequestConfiguration map to the SDK's global configuration. */
internal fun applyRequestConfiguration(params: Map<String, Any?>) {
    val builder = RequestConfiguration.Builder()

    (params["testDeviceIds"] as? List<*>)?.let { list ->
        builder.setTestDeviceIds(list.filterIsInstance<String>())
    }

    (params["tagForChildDirectedTreatment"] as? String)?.let {
        when (it) {
            "true" -> TagForChildDirectedTreatment.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE
            "false" -> TagForChildDirectedTreatment.TAG_FOR_CHILD_DIRECTED_TREATMENT_FALSE
            else -> TagForChildDirectedTreatment.TAG_FOR_CHILD_DIRECTED_TREATMENT_UNSPECIFIED
        }.also(builder::setTagForChildDirectedTreatment)
    }

    (params["tagForUnderAgeOfConsent"] as? String)?.let {
        when (it) {
            "true" -> TagForUnderAgeOfConsent.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE
            "false" -> TagForUnderAgeOfConsent.TAG_FOR_UNDER_AGE_OF_CONSENT_FALSE
            else -> TagForUnderAgeOfConsent.TAG_FOR_UNDER_AGE_OF_CONSENT_UNSPECIFIED
        }.also(builder::setTagForUnderAgeOfConsent)
    }

    (params["maxAdContentRating"] as? String)?.let {
        when (it) {
            "g" -> MaxAdContentRating.MAX_AD_CONTENT_RATING_G
            "pg" -> MaxAdContentRating.MAX_AD_CONTENT_RATING_PG
            "t" -> MaxAdContentRating.MAX_AD_CONTENT_RATING_T
            "ma" -> MaxAdContentRating.MAX_AD_CONTENT_RATING_MA
            else -> MaxAdContentRating.MAX_AD_CONTENT_RATING_UNSPECIFIED
        }.also(builder::setMaxAdContentRating)
    }

    (params["publisherPrivacyPersonalizationState"] as? String)?.let {
        when (it) {
            "enabled" -> PublisherPrivacyPersonalizationState.ENABLED
            "disabled" -> PublisherPrivacyPersonalizationState.DISABLED
            else -> PublisherPrivacyPersonalizationState.DEFAULT
        }.also(builder::setPublisherPrivacyPersonalizationState)
    }

    MobileAds.setRequestConfiguration(builder.build())
}
