package com.example.notepad_myscript_demo

import android.os.Bundle

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import io.woodemi.iink.MyscriptIinkPlugin
import com.myscript.woodemi.MyCertificate

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MyscriptIinkPlugin.initWithCertificate(this, MyCertificate.getBytes())
    }
}
