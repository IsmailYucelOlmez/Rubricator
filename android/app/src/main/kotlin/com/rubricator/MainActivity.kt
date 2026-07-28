package com.rubricator

import android.graphics.Color
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var flutterUiReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        // Hold system splash until Flutter paints first frame — avoids black gap.
        splashScreen.setKeepOnScreenCondition { !flutterUiReady }
        super.onCreate(savedInstanceState)
        // Match splash while the Flutter surface is attaching.
        window.decorView.setBackgroundColor(Color.parseColor("#F7F7F7"))
    }

    override fun onFlutterUiDisplayed() {
        flutterUiReady = true
        super.onFlutterUiDisplayed()
    }
}
