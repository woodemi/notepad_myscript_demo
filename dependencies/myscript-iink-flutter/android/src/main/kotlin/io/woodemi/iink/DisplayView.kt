package io.woodemi.iink

import android.content.Context
import android.util.Size
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.widget.FrameLayout
import com.myscript.iink.IRenderTarget
import com.myscript.iink.Renderer
import com.myscript.iink.uireferenceimplementation.LayerView
import java.util.*

class DisplayView(context: Context) : FrameLayout(context), IRenderTarget {
    init {
        for (layerType in IRenderTarget.LayerType.values()) {
            addView(LayerView(context).apply {
                type = layerType
                setCustomTypefaces(MyscriptIinkPlugin.typefaceMap)
            }, LayoutParams(MATCH_PARENT, MATCH_PARENT))
        }
    }

    var onSizeChanged: ((Size) -> Unit)? = null

    override fun onSizeChanged(newWidth: Int, newHeight: Int, oldWidth: Int, oldHeight: Int) {
        super.onSizeChanged(newWidth, newHeight, oldWidth, oldHeight)
        onSizeChanged?.invoke(Size(newWidth, newHeight))
    }

    override fun invalidate(renderer: Renderer, layers: EnumSet<IRenderTarget.LayerType>) {
        invalidate(renderer, 0, 0, width, height, layers)
    }

    override fun invalidate(renderer: Renderer, x: Int, y: Int, width: Int, height: Int, layers: EnumSet<IRenderTarget.LayerType>) {
        for (i in 0 until childCount) {
            val layerView = getChildAt(i) as LayerView
            if (layers.contains(layerView.type)) {
                layerView.update(renderer, x, y, width, height, layers)
            }
        }
    }
}