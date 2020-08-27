package com.myscript.woodemi

import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import io.woodemi.iink.MyscriptIinkPlugin

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    MyscriptIinkPlugin.initWithCertificate(this, MyCertificate.getBytes())
    GeneratedPluginRegistrant.registerWith(this)
  }
}
