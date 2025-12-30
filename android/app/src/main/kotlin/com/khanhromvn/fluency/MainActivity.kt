package com.khanhromvn.fluency

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register all Flutter plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Register our custom plugin
        FlutterPluginRegistrant.registerWith(flutterEngine)
    }
}