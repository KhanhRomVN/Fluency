package com.zenoravn.fluency

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class NotificationListenerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activityBinding: ActivityPluginBinding? = null

    companion object {
        private var _instance: NotificationListenerPlugin? = null

        fun getPluginInstance(): NotificationListenerPlugin {
            return _instance!!
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        _instance = this
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "notification_listener")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        _instance = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        // Xử lý method calls từ Flutter nếu cần
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    fun sendNotificationToFlutter(data: Map<String, Any?>) {
        channel.invokeMethod("onNotification", data)
    }
}