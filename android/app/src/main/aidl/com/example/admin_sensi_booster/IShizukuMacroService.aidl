package com.example.admin_sensi_booster;

interface IShizukuMacroService {
    void startAutoClick(int x, int y, int delayMs);
    void stopAutoClick();
    void destroy();
}
