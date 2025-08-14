package com.example.quickpost

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Explicitly allow screenshots by clearing FLAG_SECURE (in case it was set elsewhere)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
