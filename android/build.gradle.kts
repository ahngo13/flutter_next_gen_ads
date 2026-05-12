// Plugin library module for the next_gen_sdk Flutter package.

plugins {
    id("com.android.library")
    id("kotlin-android")
}

group = "com.siwooeo.flutter_next_gen_ads"
version = "1.0.0"

android {
    namespace = "com.siwooeo.flutter_next_gen_ads"
    compileSdk = 35

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

dependencies {
    implementation("com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
}
