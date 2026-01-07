``` flutter run qua adb usb
khanhromvn@UbuntuLTS:~/Documents/Coding/Fluency/Fluency$ flutter run
Connected devices:
V2110 (mobile)  • 3428675950002NZ     • android-arm64  • Android 13 (API 33)
V2110 (mobile)  • 192.168.101.62:5555 • android-arm64  • Android 13 (API 33)
Linux (desktop) • linux               • linux-x64      • Ubuntu 24.04.3 LTS
6.14.0-37-generic
Chrome (web)    • chrome              • web-javascript • Google Chrome 142.0.7444.59

Wirelessly connected devices:
V2110 (wireless) (mobile) • adb-3428675950002NZ-JP0YBz._adb-tls-connect._tcp •
android-arm64 • Android 13 (API 33)

[1]: V2110 (3428675950002NZ)
[2]: V2110 (192.168.101.62:5555)
[3]: Linux (linux)
[4]: Chrome (chrome)
[5]: V2110 (wireless) (adb-3428675950002NZ-JP0YBz._adb-tls-connect._tcp)
Please choose one (or "q" to quit): 1
Launching lib/main.dart on V2110 in debug mode...
Running Gradle task 'assembleDebug'...                           2,743ms
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...          96.6s
I/flutter (18795): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(61)] Using the Impeller rendering backend (Vulkan).
W/FlutterEngineCxnRegstry(18795): Attempted to register plugin (xyz.luan.audioplayers.AudioplayersPlugin@54cd809) but it was already registered with this FlutterEngine (io.flutter.embedding.engine.FlutterEngine@b80ea0e).
W/FlutterEngineCxnRegstry(18795): Attempted to register plugin (com.mr.flutter.plugin.filepicker.FilePickerPlugin@2081c2f) but it was already registered with this FlutterEngine (io.flutter.embedding.engine.FlutterEngine@b80ea0e).
W/FlutterEngineCxnRegstry(18795): Attempted to register plugin (io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin@164823c) but it was already registered with this FlutterEngine (io.flutter.embedding.engine.FlutterEngine@b80ea0e).
W/FlutterEngineCxnRegstry(18795): Attempted to register plugin (io.flutter.plugins.pathprovider.PathProviderPlugin@de1ebc5) but it was already registered with this FlutterEngine (io.flutter.embedding.engine.FlutterEngine@b80ea0e).
D/BufferQueueConsumer(18795): [](id:496b00000000,api:0,p:-1,c:18795) connect: controlledByApp=false
E/FBI     (18795): Can't load library: dlopen failed: library "libmagtsync.so" not found
I/nhromvn.fluency(18795): Compiler allocated 5508KB to compile void android.view.ViewRootImpl.performTraversals()
E/OpenGLRenderer(18795): Device claims wide gamut support, cannot find matching config, error = EGL_SUCCESS
W/OpenGLRenderer(18795): Failed to initialize 101010-2 format, error = EGL_SUCCESS
D/skia    (18795): GrGLMakeAssembledInterface verStr OpenGL ES 3.2 v1.r26p0-01eac0.455662e55e7c7fb95a4b1db7e7af49a8
D/skia    (18795): GrGLMakeAssembledGLESInterface verStr OpenGL ES 3.2 v1.r26p0-01eac0.455662e55e7c7fb95a4b1db7e7af49a8
D/skia    (18795): extensions init verString=OpenGL ES 3.2 v1.r26p0-01eac0.455662e55e7c7fb95a4b1db7e7af49a8
D/BufferQueueConsumer(18795): [](id:496b00000001,api:0,p:-1,c:18795) connect: controlledByApp=false
E/gralloc4(18795): ERROR: Format allocation info not found for format: 38
E/gralloc4(18795): ERROR: Format allocation info not found for format: 0
E/gralloc4(18795): Invalid base format! req_base_format = 0x0, req_format = 0x38, type = 0x0
E/gralloc4(18795): ERROR: Unrecognized and/or unsupported format 0x38 and usage 0xb00
E/Gralloc4(18795): isSupported(1, 1, 56, 1, ...) failed with 5
E/GraphicBufferAllocator(18795): Failed to allocate (4 x 4) layerCount 1 format 56 usage b00: 5
E/AHardwareBuffer(18795): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
E/gralloc4(18795): ERROR: Format allocation info not found for format: 38
E/gralloc4(18795): ERROR: Format allocation info not found for format: 0
E/gralloc4(18795): Invalid base format! req_base_format = 0x0, req_format = 0x38, type = 0x0
E/gralloc4(18795): ERROR: Unrecognized and/or unsupported format 0x38 and usage 0xb00
E/Gralloc4(18795): isSupported(1, 1, 56, 1, ...) failed with 5
E/GraphicBufferAllocator(18795): Failed to allocate (4 x 4) layerCount 1 format 56 usage b00: 5
E/AHardwareBuffer(18795): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
E/ion     (18795): ioctl c0044901 failed with code -1: Invalid argument
D/hw-ProcessState(18795): Binder ioctl to enable oneway spam detection failed: Invalid argument
Syncing files to device V2110...                                   109ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on V2110 is available at: http://127.0.0.1:41645/2bwDQ_BLRzg=/
D/BLASTBufferQueue(18795): [SurfaceView[com.khanhromvn.fluency/com.khanhromvn.fluency.MainActivity]#1](f:0,a:1) acquireNextBufferLocked size=720x1521 mFrameNumber=1 applyTransaction=true mTimestamp=69975624050400(auto) mPendingTransactions.size=0 graphicBufferId=80723910328330 transform=0
The Flutter DevTools debugger and profiler on V2110 is available at:
http://127.0.0.1:9102?uri=http://127.0.0.1:41645/2bwDQ_BLRzg=/
I/Choreographer(18795): Skipped 53 frames!  The application may be doing too much work on its main thread.
D/BLASTBufferQueue(18795): [VRI[MainActivity]#0](f:0,a:1) acquireNextBufferLocked size=720x1600 mFrameNumber=1 applyTransaction=true mTimestamp=69976593161170(auto) mPendingTransactions.size=0 graphicBufferId=80723910328335 transform=0
W/Parcel  (18795): Expecting binder but got null!
I/OpenGLRenderer(18795): Davey! duration=949ms; Flags=1, FrameTimelineVsyncId=13269132, IntendedVsync=69975644332728, Vsync=69976526853112, InputEventId=0, HandleInputStart=69976543319247, AnimationStart=69976543323247, PerformTraversalsStart=69976543324247, DrawStart=69976549994016, FrameDeadline=69975664332728, FrameInterval=69976543162939, FrameStartTime=16651328, SyncQueued=69976551828170, SyncStart=69976552098939, IssueDrawCommandsStart=69976553152785, SwapBuffers=69976591061477, FrameCompleted=69976594303939, DequeueBufferDuration=11210692, QueueBufferDuration=554077, GpuCompleted=69976594303939, SwapBuffersCompleted=69976593973400, DisplayPresentTime=2, CommandSubmissionCompleted=69976591061477, 
V/ImeFocusController(18795): onWindowFocus: DecorView@8e816cc[MainActivity] softInputMode=STATE_UNSPECIFIED|ADJUST_RESIZE|IS_FORWARD_NAVIGATION
V/ImeFocusController(18795): Restarting due to isRestartOnNextWindowFocus as true
D/ImeFocusController(18795): onViewFocusChanged, view=DecorView@8e816cc[MainActivity], mServedView=null
V/ImeFocusController(18795): checkFocus: view=null next=DecorView@8e816cc[MainActivity] immDelegate=delegate{3b1c9cd displayId=0} force=true package=<none>
D/ProfileInstaller(18795): Installing profile for com.khanhromvn.fluency
```

