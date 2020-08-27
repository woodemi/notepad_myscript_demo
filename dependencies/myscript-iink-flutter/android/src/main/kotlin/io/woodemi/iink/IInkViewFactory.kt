package io.woodemi.iink

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class IInkViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, creationParams: Any?): PlatformView {
        val map = creationParams as? Map<String, Any> ?: throw Exception("Unknown creationParams")
        return when (map["type"]) {
            EditorView.TAG -> EditorView(context, messenger, id).also {
                platformViews[id] = it
            }
            else -> throw Exception("Unimplemented view")
        }
    }

    private val platformViews = mutableMapOf<Int, PlatformView>()

    fun <T : PlatformView> findViewById(id: Int): T {
        return platformViews[id] as? T ?: throw Exception("PlatformView $id not found")
    }

    fun releaseViewById(id: Int) {
        platformViews.remove(id)
    }
}