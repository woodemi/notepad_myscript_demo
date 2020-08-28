package io.woodemi.iink

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.util.Size
import com.myscript.iink.*
import com.myscript.iink.uireferenceimplementation.Canvas
import io.flutter.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.*

private val mainThreadHandler = Handler(Looper.getMainLooper())

class EditorController(messenger: BinaryMessenger, channelName: String) : MethodChannel.MethodCallHandler {
    companion object {
        const val TAG = "editor_controller"
    }

    private lateinit var editor: Editor
    private var renderTarget: IRenderTarget? = null

    init {
        MethodChannel(messenger, channelName).setMethodCallHandler(this)
    }

    fun close() {
        editor.waitForIdle()
        editor.part?.`package`?.close()
        editor.renderer.close()
        editor.close()
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "onMethodCall ${methodCall.method}")
        when (methodCall.method) {
            "initRenderEditor" -> {
                val viewScale = methodCall.argument<Double>("viewScale")
                val DpiX = methodCall.argument<Double>("DpiX")
                val DpiY = methodCall.argument<Double>("DpiY")

                initRenderEditor(DpiX!!.toFloat(), DpiY!!.toFloat())
                editor.renderer.viewScale = viewScale!!.toFloat()
                mainThreadHandler.post { result.success(null) }
            }
            "createPackage" -> {
                val path = methodCall.argument<String>("path")
                val contentPackage = MyscriptIinkPlugin.engine.createPackage(path)
                editor.part = contentPackage.createPart("Text")
                renderTarget?.invalidate(editor.renderer, EnumSet.allOf(IRenderTarget.LayerType::class.java))
                mainThreadHandler.post { result.success(null) }
            }
            "openPackage" -> {
                val path = methodCall.argument<String>("path")
                val contentPackage = MyscriptIinkPlugin.engine.openPackage(path)
                editor.part = contentPackage.getPart(0)
                renderTarget?.invalidate(editor.renderer, EnumSet.allOf(IRenderTarget.LayerType::class.java))
                mainThreadHandler.post { result.success(null) }
            }
            "bindPlatformView" -> {
                val id = methodCall.argument<Int>("id")!!
                val editorView = MyscriptIinkPlugin.iInkViewFactory.findViewById<EditorView>(id)
                renderTarget = editorView.displayView
                renderTarget?.invalidate(editor.renderer, EnumSet.allOf(IRenderTarget.LayerType::class.java))
                mainThreadHandler.post { result.success(null) }
            }
            "unbindPlatformView" -> {
                val id = methodCall.argument<Int>("id")!!
                MyscriptIinkPlugin.iInkViewFactory.releaseViewById(id)
                renderTarget = null
                mainThreadHandler.post { result.success(null) }
            }
            "setPenStyle" -> {
                this.editor.penStyle = (methodCall.argument<String>("penStyle"))!!
                mainThreadHandler.post { result.success(null) }
            }
            "getPenStyle" -> {
                val penStyle = this.editor.penStyle
                mainThreadHandler.post { result.success(penStyle) }
            }
            "syncPointerEvent" -> {
                handleSyncPointerEvent(methodCall)
                mainThreadHandler.post { result.success(null) }
            }
            "syncPointerEvents" -> {
                Thread {
                    handleSyncPointerEvents(methodCall.arguments as List<Map<String, Any>>)
                    mainThreadHandler.post { result.success(null) }
                }.start()
            }
            "exportText" -> {
                this.editor.part.`package`.save()
                try {
                    val text = this.editor.export_(null, MimeType.TEXT)
                    mainThreadHandler.post { result.success(text) }
                } catch (e: Exception) {
                    mainThreadHandler.post { result.error(e.localizedMessage, "", "") }
                }
            }
            "exportJIIX" -> {
                this.editor.part.`package`.save()
                try {
                    val jiix = this.editor.export_(null, MimeType.JIIX)
                    mainThreadHandler.post { result.success(jiix) }
                } catch (e: Exception) {
                    mainThreadHandler.post { result.error(e.localizedMessage, "", "") }
                }
            }
            "exportPNG" -> {
                Thread {
                    val background = methodCall.argument<ByteArray>("gifPathName")
                    val imageBytes = editor.createImage(_displayViewSize().width, _displayViewSize().height, background)
                    mainThreadHandler.post { result.success(imageBytes) }
                }.start()
            }
            "exportJPG" -> {
                Thread {
                    val background = methodCall.argument<ByteArray>("skinBytes")
                    val imageBytes = editor.createImage(_displayViewSize().width, _displayViewSize().height, background)
                    mainThreadHandler.post { result.success(imageBytes) }
                }.start()
            }
            "exportGIF" -> {
                Thread {
                    val gifPath = methodCall.argument<String>("gifPath")!!
                    var bitmaps = createGifBitmaps(methodCall)
                    var gifFilePath = createGif(bitmaps, gifPath)
                    mainThreadHandler.post { result.success(gifFilePath) }
                }.start()
            }
            "clear" -> {
                this.editor.clear()
                var contentPackage = this.editor.part.`package`
                contentPackage.removePart(this.editor.part)
                contentPackage.createPart("Text")
                this.editor.part = contentPackage.getPart(0)
                contentPackage.save()
                mainThreadHandler.post { result.success(null) }
            }
            "canUndo" -> {
                mainThreadHandler.post {
                    if (!this.editor.isClosed) {
                        this.editor.canUndo()
                    }
                }
            }
            "undo" -> {
                mainThreadHandler.post {
                    if (!this.editor.isClosed) {
                        if (this.editor.canUndo()) {
                            this.editor.undo()
                        }
                        result.success(this.editor.canUndo())
                    }
                }
            }
            "canRedo" -> {
                mainThreadHandler.post {
                    if (!this.editor.isClosed) {
                        this.editor.canRedo()
                    }
                }
            }
            "redo" -> {
                if (!this.editor.isClosed) {
                    if (this.editor.canRedo()) {
                        this.editor.redo()
                    }
                    result.success(this.editor.canRedo())
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun initRenderEditor(xdpi: Float, ydpi: Float) {
        val renderer = MyscriptIinkPlugin.engine.createRenderer(xdpi, ydpi, object : IRenderTarget {
            override fun invalidate(renderer: Renderer, layers: EnumSet<IRenderTarget.LayerType>) {
                renderTarget?.invalidate(renderer, layers)
            }

            override fun invalidate(renderer: Renderer, x: Int, y: Int, width: Int, height: Int, layers: EnumSet<IRenderTarget.LayerType>) {
                renderTarget?.invalidate(renderer, x, y, width, height, layers)
            }
        })
        editor = MyscriptIinkPlugin.engine.createEditor(renderer)
        editor.setFontMetricsProvider(MyscriptIinkPlugin.fontMetricsProvider)
    }

    fun handleSyncPointerEvent(methodCall: MethodCall) {
        val eventType = (methodCall.argument<String>("eventType"))!!
        val x = methodCall.argument<Double>("x")!!
        val y = methodCall.argument<Double>("y")!!
        val t = methodCall.argument<Int>("t")!!
        val f = methodCall.argument<Double>("f")!!
        val pointerType = (methodCall.argument<String>("pointerType"))!!
        val pointerId = methodCall.argument<Int>("pointerId")!!

        when (eventType) {
            "down" -> {
                this.editor.pointerDown(x.toFloat(), y.toFloat(), t.toLong(), f.toFloat(), formatWithPointerType(pointerType), pointerId)
            }
            "move" -> {
                this.editor.pointerMove(x.toFloat(), y.toFloat(), t.toLong(), f.toFloat(), formatWithPointerType(pointerType), pointerId)
            }
            "up" -> {
                this.editor.pointerUp(x.toFloat(), y.toFloat(), t.toLong(), f.toFloat(), formatWithPointerType(pointerType), pointerId)
                this.editor.part.`package`.save()
                Log.d(TAG, "this.editor.part.`package`.save()")
            }
            "cancel" -> {
                this.editor.pointerCancel(pointerId)
            }
        }
    }

    fun handleSyncPointerEvents(methodCall: List<Map<String, Any>>) {
        val pointerEventList = mutableListOf<PointerEvent>()
        for (map in methodCall) {
            val eventType: String = map["eventType"].toString()
            val x = map["x"].toString().toDouble()
            val y = map["y"].toString().toDouble()
            val t = map["t"].toString().toDouble()
            val f = map["f"].toString().toDouble()
            val pointerType = map["pointerType"].toString()
            val pointerId = map["pointerId"].toString().toInt()
            when (eventType) {
                "down" -> {
                    pointerEventList.add(PointerEvent(PointerEventType.DOWN, x.toFloat(), y.toFloat(), t.toLong(), f.toFloat(), formatWithPointerType(pointerType), pointerId))
                }
                "move" -> {
                    pointerEventList.add(PointerEvent(PointerEventType.MOVE, x.toFloat(), y.toFloat(), t.toLong(), f.toFloat(), formatWithPointerType(pointerType), pointerId))
                }
                "up" -> {
                    pointerEventList.add(PointerEvent(PointerEventType.UP, x.toFloat(), y.toFloat(), t.toLong(), f.toFloat(), formatWithPointerType(pointerType), pointerId))
                }
                "cancel" -> {
                    pointerEventList.add(PointerEvent(PointerEventType.CANCEL, x.toFloat(), y.toFloat(), t.toLong(), f.toFloat(), formatWithPointerType(pointerType), pointerId))
                }
            }
        }
        if (!editor.isClosed) {
            editor.pointerEvents(pointerEventList.toTypedArray(), false)
            if (this.editor.part != null) {
                if (!this.editor.part.`package`.isClosed) {
                    this.editor.part.`package`.save()
                }
            }
            this.editor.waitForIdle()
        }
    }

    fun formatWithPointerType(type: String): PointerType {
        when (type) {
            "pen" -> {
                return PointerType.PEN
            }
            "touch" -> {
                return PointerType.TOUCH
            }
            "eraser" -> {
                return PointerType.ERASER
            }
        }
        return PointerType.PEN
    }

    private fun _displayViewSize(): Size {
        return Size(MyscriptIinkPlugin.displayMetrics.widthPixels, (MyscriptIinkPlugin.displayMetrics.widthPixels * 1.32).toInt());
    }

    private fun createGifBitmaps(methodCall: MethodCall): List<Bitmap> {
        val bitmaps = mutableListOf<Bitmap>()
        val background = methodCall.argument<ByteArray>("skinBytes")!!
        var arr = methodCall.argument<List<List<Map<String, Any>>>>("parts")!!

        for (map in arr) {
            handleSyncPointerEvents(map)
            this.editor.part.`package`.save()
            this.editor.waitForIdle()
            val imageBytes = editor.createImage(_displayViewSize().width, _displayViewSize().height, background)
            var bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            bitmaps.add(bitmap)
        }
        return bitmaps;
    }

    private fun createGif(bitmaps: List<Bitmap>, gifPath: String): String {
        AnimatedGifEncoder().run {
            start(gifPath)
            setRepeat(0) // 设置生成gif的开始播放时间。0为立即开始播放
            setDelay(100)
            bitmaps.forEach { addFrame(Bitmap.createScaledBitmap(it, _displayViewSize().width, _displayViewSize().height, false)) }
            finish()
        }
        return gifPath
    }

}

private fun Editor.createImage(width: Int, height: Int, background: ByteArray?): ByteArray {
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
    val sysCanvas = android.graphics.Canvas(bitmap)
    background?.let {
        var oldBitmap = BitmapFactory.decodeByteArray(it, 0, it.size)
        var newBitmap = Bitmap.createScaledBitmap(oldBitmap, width, height, true)
        sysCanvas.drawBitmap(newBitmap, 0f, 0f, null)
        newBitmap.recycle()
    }

    Canvas(sysCanvas, MyscriptIinkPlugin.typefaceMap, null, null).let {
        if (!renderer.isClosed) {
            renderer.drawModel(0, 0, bitmap.width, bitmap.height, it)
            renderer.drawTemporaryItems(0, 0, bitmap.width, bitmap.height, it)
            renderer.drawCaptureStrokes(0, 0, bitmap.width, bitmap.height, it)
        }
    }

    return ByteArrayOutputStream(bitmap.byteCount).also {
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        bitmap.recycle()
    }.toByteArray()
}
