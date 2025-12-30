package com.khanhromvn.fluency

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.PluginRegistry

object FlutterPluginRegistrant {
    fun registerWith(flutterEngine: FlutterEngine) {
        if (alreadyRegisteredWith(flutterEngine)) {
            return
        }
        
        flutterEngine.plugins.add(NotificationListenerPlugin())
    }

    private fun alreadyRegisteredWith(flutterEngine: FlutterEngine): Boolean {
        val key = FlutterPluginRegistrant::class.java.canonicalName
        if (flutterEngine.plugins.has(NotificationListenerPlugin::class.java)) {
            return true
        }
        return false
    }
}