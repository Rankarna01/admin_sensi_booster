package com.example.admin_sensi_booster

import com.example.admin_sensi_booster.macro.MacroEngine

class ShizukuMacroService : IShizukuMacroService.Stub() {

    override fun startAutoClick(x: Int, y: Int, delayMs: Int) {
        MacroEngine.startAutoClick(x, y, delayMs)
    }

    override fun stopAutoClick() {
        MacroEngine.stopAutoClick()
    }

    override fun destroy() {
        MacroEngine.destroy()
        System.exit(0)
    }
}
