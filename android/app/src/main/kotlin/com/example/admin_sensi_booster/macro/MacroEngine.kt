package com.example.admin_sensi_booster.macro

object MacroEngine {
    private var isRunning = false
    private var macroThread: Thread? = null

    // Standar Pointer ID Android (Mulai dari 0 & 1 agar tidak di-reject game/sistem)
    const val JOYSTICK_FINGER_ID = 0
    const val CLICK_FINGER_ID = 1

    fun startAutoClick(x: Int, y: Int, delayMs: Int) {
        if (isRunning) return
        isRunning = true
        
        macroThread = kotlin.concurrent.thread(start = true) {
            try {
                while (isRunning) {
                    VirtualTouchManager.down(CLICK_FINGER_ID, x.toFloat(), y.toFloat())
                    Thread.sleep(15) // Waktu tahan (hold)
                    VirtualTouchManager.up(CLICK_FINGER_ID)
                    
                    Thread.sleep(delayMs.toLong())
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                VirtualTouchManager.up(CLICK_FINGER_ID)
            }
        }
    }

    fun stopAutoClick() {
        isRunning = false
        macroThread?.interrupt()
        macroThread = null
        VirtualTouchManager.up(CLICK_FINGER_ID)
    }

    fun destroy() {
        stopAutoClick()
        VirtualTouchManager.releaseAll()
    }
}
