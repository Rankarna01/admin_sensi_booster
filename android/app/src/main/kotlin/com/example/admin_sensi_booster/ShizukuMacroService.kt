package com.example.admin_sensi_booster

import android.hardware.input.InputManager
import android.os.SystemClock
import android.view.InputDevice
import android.view.InputEvent
import android.view.MotionEvent
import kotlin.concurrent.thread

class ShizukuMacroService : IShizukuMacroService.Stub() {
    private var isRunning = false
    private var macroThread: Thread? = null

    override fun startAutoClick(x: Int, y: Int, delayMs: Int) {
        if (isRunning) return
        isRunning = true
        macroThread = thread(start = true) {
            try {
                val inputManagerClass = Class.forName("android.hardware.input.InputManager")
                val getInstanceMethod = inputManagerClass.getDeclaredMethod("getInstance")
                val inputManager = getInstanceMethod.invoke(null)
                
                val injectMethod = inputManagerClass.getDeclaredMethod("injectInputEvent", InputEvent::class.java, Int::class.javaPrimitiveType)
                
                while (isRunning) {
                    val downTime = SystemClock.uptimeMillis()
                    
                    // Create PointerProperties and PointerCoords to simulate a specific pointer ID (e.g. ID 5)
                    // This helps to prevent conflicts with the user's real finger (which is usually ID 0 or 1).
                    val properties = arrayOfNulls<MotionEvent.PointerProperties>(1)
                    val prop = MotionEvent.PointerProperties()
                    prop.id = 5
                    prop.toolType = MotionEvent.TOOL_TYPE_FINGER
                    properties[0] = prop
                    
                    val coords = arrayOfNulls<MotionEvent.PointerCoords>(1)
                    val coord = MotionEvent.PointerCoords()
                    coord.x = x.toFloat()
                    coord.y = y.toFloat()
                    coord.pressure = 1.0f
                    coord.size = 1.0f
                    coords[0] = coord
                    
                    // Action down
                    val downEvent = MotionEvent.obtain(
                        downTime, downTime, MotionEvent.ACTION_DOWN, 1,
                        properties as Array<MotionEvent.PointerProperties>,
                        coords as Array<MotionEvent.PointerCoords>,
                        0, 0, 1.0f, 1.0f, 99, 0, InputDevice.SOURCE_TOUCHSCREEN, 0
                    )
                    
                    injectMethod.invoke(inputManager, downEvent, 0) // 0 = INJECT_INPUT_EVENT_MODE_ASYNC
                    downEvent.recycle()
                    
                    Thread.sleep(10) // Small hold duration
                    
                    // Action up
                    val upEvent = MotionEvent.obtain(
                        downTime, SystemClock.uptimeMillis(), MotionEvent.ACTION_UP, 1,
                        properties,
                        coords,
                        0, 0, 1.0f, 1.0f, 99, 0, InputDevice.SOURCE_TOUCHSCREEN, 0
                    )
                    injectMethod.invoke(inputManager, upEvent, 0)
                    upEvent.recycle()
                    
                    Thread.sleep(delayMs.toLong())
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun stopAutoClick() {
        isRunning = false
        macroThread?.interrupt()
        macroThread = null
    }

    override fun destroy() {
        stopAutoClick()
        System.exit(0)
    }
}
