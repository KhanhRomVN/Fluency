# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep TensorFlow Lite Support
-keep class org.tensorflow.lite.support.** { *; }

# Keep required classes
-dontwarn org.tensorflow.lite.gpu.**

# Google Sign In
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.signin.internal.** { *; }
-keep class com.google.android.gms.common.internal.safeparcel.SafeParcelable { *; }
-keepnames class com.google.android.gms.common.internal.ReflectedParcelable
-keepnames @com.google.android.gms.common.annotation.KeepName class *
-keepclassmembernames class * {
    @com.google.android.gms.common.annotation.KeepName *;
}
-dontwarn com.google.android.gms.**

# AutoValue
-keep class com.google.auto.value.** { *; }
-dontwarn com.google.auto.value.**