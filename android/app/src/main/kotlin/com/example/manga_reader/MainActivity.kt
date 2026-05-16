package com.example.manga_reader

import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.android.FlutterView

class MainActivity : FlutterActivity() {
    override fun onStart() {
        super.onStart()

        // 处理flutter中Focus组件无法接收音量键的问题
        // 这是flutter已知问题https://github.com/flutter/flutter/issues/71144
        // 解决方案来自该issue下用户@khjde1207的评论
        val view = window.findViewById<ViewGroup>(FLUTTER_VIEW_ID).getChildAt(0) as FlutterSurfaceView
        if (view.parent is FlutterView) {
            val pview = view.parent as FlutterView
            pview.requestFocus()
            view.requestFocus()
        }
    }
}
