package com.example.admin_sensi_booster.macro

import android.os.SystemClock
import android.view.InputDevice
import android.view.MotionEvent

data class Finger(val id: Int, var x: Float, var y: Float)

object VirtualTouchManager {
    private val activeFingers = mutableListOf<Finger>()
    private var downTime: Long = 0

    fun down(id: Int, x: Float, y: Float) {
        if (activeFingers.any { it.id == id }) return 
        
        val finger = Finger(id, x, y)
        activeFingers.add(finger)
        
        if (activeFingers.size == 1) {
            downTime = SystemClock.uptimeMillis()
            sendEvent(MotionEvent.ACTION_DOWN, 0)
        } else {
            val pointerIndex = activeFingers.indexOf(finger)
            val action = MotionEvent.ACTION_POINTER_DOWN or (pointerIndex shl MotionEvent.ACTION_POINTER_INDEX_SHIFT)
            sendEvent(action, pointerIndex)
        }
    }

    fun move(id: Int, x: Float, y: Float) {
        val finger = activeFingers.find { it.id == id } ?: return
        finger.x = x
        finger.y = y
        sendEvent(MotionEvent.ACTION_MOVE, activeFingers.indexOf(finger))
    }

    fun up(id: Int) {
        val fingerIndex = activeFingers.indexOfFirst { it.id == id }
        if (fingerIndex == -1) return

        if (activeFingers.size == 1) {
            sendEvent(MotionEvent.ACTION_UP, 0)
            activeFingers.clear()
        } else {
            val action = MotionEvent.ACTION_POINTER_UP or (fingerIndex shl MotionEvent.ACTION_POINTER_INDEX_SHIFT)
            sendEvent(action, fingerIndex)
            activeFingers.removeAt(fingerIndex)
        }
    }
    
    fun releaseAll() {
        while (activeFingers.isNotEmpty()) {
            up(activeFingers.last().id)
        }
    }

    private fun sendEvent(action: Int, actionIndex: Int) {
        if (activeFingers.isEmpty()) return
        
        val pointerCount = activeFingers.size
        val properties = arrayOfNulls<MotionEvent.PointerProperties>(pointerCount)
        val coords = arrayOfNulls<MotionEvent.PointerCoords>(pointerCount)
        
        for (i in 0 until pointerCount) {
            val finger = activeFingers[i]
            
            val prop = MotionEvent.PointerProperties()
            prop.id = finger.id
            prop.toolType = MotionEvent.TOOL_TYPE_FINGER
            properties[i] = prop
            
            val coord = MotionEvent.PointerCoords()
            coord.x = finger.x
            coord.y = finger.y
            coord.pressure = 1.0f
            coord.size = 1.0f
            coords[i] = coord
        }

        val eventTime = SystemClock.uptimeMillis()
        
        val event = MotionEvent.obtain(
            downTime, 
            eventTime, 
            action, 
            pointerCount,
            properties as Array<MotionEvent.PointerProperties>, 
            coords as Array<MotionEvent.PointerCoords>, 
            0, 
            0, 
            1.0f, 
            1.0f, 
            0, // deviceId standar agar tidak di-reject game
            0, 
            InputDevice.SOURCE_TOUCHSCREEN, 
            0 // Hapus FLAG_IS_ACCESSIBILITY_EVENT karena menyebabkan system crash jika dikirim dari luar system server
        )
        InputInjector.inject(event)
        event.recycle()
    }
}
