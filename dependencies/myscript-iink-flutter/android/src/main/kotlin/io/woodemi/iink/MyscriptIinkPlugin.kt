package io.woodemi.iink

import android.content.Context
import android.graphics.Typeface
import android.util.DisplayMetrics
import com.myscript.iink.Engine
import com.myscript.iink.uireferenceimplementation.FontMetricsProvider
import com.myscript.iink.uireferenceimplementation.FontUtils
import io.flutter.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

var iink_controllers: MutableMap<String, EditorController> = mutableMapOf()

class MyscriptIinkPlugin: MethodCallHandler {
    companion object {
        const val PACKAGE_NAME = "myscript_iink"

        lateinit var engine: Engine
            private set

        lateinit var typefaceMap: Map<String, Typeface>
            private set

        lateinit var fontMetricsProvider: FontMetricsProvider
            private set

        lateinit var iInkViewFactory: IInkViewFactory
            private set

        lateinit var displayMetrics: DisplayMetrics
            private set

        @JvmStatic
        fun initWithCertificate(context: Context, bytes: ByteArray) {
            Log.d(EditorController.TAG, "Android initWithCertificate")
            engine = Engine.create(bytes)
            val confDir = "zip://${context.packageCodePath}!/assets/recognition-assets/conf"
            engine.configuration.setStringArray("configuration-manager.search-path", arrayOf(confDir))
            engine.configuration.setBoolean("text.guides.enable", false)
            engine.configuration.setString("content-package.temp-folder", "${context.filesDir.path}/tmp")
            engine.configuration.setBoolean("gesture.enable", false)
            typefaceMap = FontUtils.loadFontsFromAssets(context.assets)
            fontMetricsProvider = FontMetricsProvider(context.resources.displayMetrics, typefaceMap)
            displayMetrics = context.resources.displayMetrics
        }

        lateinit var iink_registrar: Registrar
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            iink_registrar = registrar
            iInkViewFactory = IInkViewFactory(registrar.messenger())
            registrar.platformViewRegistry().registerViewFactory("iink_view", iInkViewFactory)

            MethodChannel(registrar.messenger(), PACKAGE_NAME).setMethodCallHandler(MyscriptIinkPlugin())
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "createEditorControllerChannel" -> {
                val channelName = call.argument<String>("channelName")!!
                createChannel(channelName)
                result.success(null)
            }
            "closeEditorControllerChannel" -> {
                val channelName = call.argument<String>("channelName")!!
                closeChannel(channelName)
                result.success(null)
            }
            "setEngineConfiguration_Language" -> {
                val lang = call.argument<String>("lang")
                engine.configuration.setString("lang", lang)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun createChannel(channelName: String): EditorController {
        if (iink_controllers.containsKey(channelName)) {
            return iink_controllers[channelName]!!
        }
        var controller = EditorController(iink_registrar.messenger(), channelName!!)
        iink_controllers.put(channelName, controller)
        return controller
    }

    private fun closeChannel(channelName: String) {
        if (iink_controllers.containsKey(channelName)) {
            Thread {
                var controller= iink_controllers[channelName]!!
                controller.close()
                iink_controllers.remove(channelName)
            }.start()
        }
    }
}
