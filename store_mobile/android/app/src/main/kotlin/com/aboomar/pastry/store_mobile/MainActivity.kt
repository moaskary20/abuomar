package com.aboomar.pastry.store_mobile

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        keepSystemBarsReserved()
    }

    override fun onPostResume() {
        super.onPostResume()
        // Flutter قد يعيد تفعيل edge-to-edge — نثبّت المساحة بعد الاستئناف
        keepSystemBarsReserved()
    }

    private fun keepSystemBarsReserved() {
        WindowCompat.setDecorFitsSystemWindows(window, true)
    }
}
