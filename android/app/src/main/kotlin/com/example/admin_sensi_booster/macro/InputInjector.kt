package com.example.admin_sensi_booster.macro

import android.view.InputEvent
import android.view.MotionEvent
import java.lang.reflect.Method

object InputInjector {
    private var inputManager: Any? = null
    private var injectMethod: Method? = null

    init {
        try {
            val inputManagerClass = Class.forName("android.hardware.input.InputManager")
            val getInstanceMethod = inputManagerClass.getDeclaredMethod("getInstance")
            inputManager = getInstanceMethod.invoke(null)
            
            injectMethod = inputManagerClass.getDeclaredMethod(
                "injectInputEvent", 
                InputEvent::class.java, 
                Int::class.javaPrimitiveType
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun inject(event: MotionEvent) {
        try {
            // 0 = INJECT_INPUT_EVENT_MODE_ASYNC
            injectMethod?.invoke(inputManager, event, 0)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
