package com.zenoravn.fluency

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Note: GeneratedPluginRegistrant is called automatically by super.configureFlutterEngine(flutterEngine)
        // in modern Flutter versions. Manually calling it can cause duplicate registration warnings.
        
        // Register our custom plugin
        FlutterPluginRegistrant.registerWith(flutterEngine)
    }
}