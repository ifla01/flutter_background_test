package com.ina.test.foreground.foreground_test2

import android.annotation.SuppressLint
import android.os.Handler
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity: FlutterActivity(), EventChannel.StreamHandler {
    private val channel = "foreground/test"
    private val eventChannel: String = "foreground/event"
    var resultSink: EventChannel.EventSink? = null
    var handler: Handler? = Handler()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 이벤트 결과
        var result = EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannel)
        result.setStreamHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            if (call.method == "start") {
                Log.d("foreground", "start()")
                handler?.post(runnable)
            } else if(call.method == "stop") {
                Log.d("foreground", "stop()")
                handler?.removeCallbacks(runnable)
            }
        }
    }

    private val runnable = Runnable {
        sendNewRandomNumber()
    }

    private fun sendNewRandomNumber() {
        val randomNumber = Random().nextInt(9)
        handler?.postDelayed(runnable, 1000)
        resultSink?.success(randomNumber.toString())
        Log.d("log", "$randomNumber")
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        resultSink = events
    }

    override fun onCancel(arguments: Any?) {
        resultSink = null
        handler?.removeCallbacks(runnable)
    }
}