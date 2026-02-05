package com.zenoravn.fluency

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

class FluencyApplication : FlutterApplication() {
    lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()

        // Initialize Flutter Engine
        
        // Register plugins
        FlutterPluginRegistrant.registerWith(flutterEngine)
        
        // Cache the Flutter Engine
        FlutterEngineCache.getInstance().put("fluency_engine", flutterEngine)
    }
}