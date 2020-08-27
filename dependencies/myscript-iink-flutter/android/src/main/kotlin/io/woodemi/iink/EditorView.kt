package io.woodemi.iink

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.util.Log
import android.view.View
import android.view.Window
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import java.lang.Exception

class EditorView(context: Context, messenger: BinaryMessenger, id: Int) : PlatformView {
    companion object {
        const val TAG = "editor_view"
    }

    val displayView = DisplayView(context).apply {
        // FIXME https://github.com/flutter/flutter/issues/33756
        post { getWindow()?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT)) }
        onSizeChanged = {
            // TODO
        }
    }

    override fun getView(): View = displayView

    override fun dispose() {

    }
}

private fun View.getWindow(): Window? {
    // FIXME Reflection diffs below Android-N
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return null

    var p = parent
    while (p.parent != null) {
        p = p.parent
    }

    try {
        val decorView = p.javaClass.getDeclaredMethod("getView").invoke(p) as View
        val windowField = decorView.javaClass.getDeclaredField("mWindow")
        windowField.isAccessible = true
        return windowField.get(decorView) as Window
    } catch (error: Exception) {
        Log.e("View.getWindow()", "error: $error")
    }

    return null
}
