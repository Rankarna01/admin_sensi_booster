import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../seeder/admin_seeder.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/base_layout.dart'; // Import background grid
import '../dashboard/admin_dashboard_page.dart';
import '../layouts/client_main_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _rememberDevice = true; // State untuk toggle switch

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password tidak boleh kosong!")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    String? result = await _authService.loginAndGetRole(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() { _isLoading = false; });

    if (result != null && result.startsWith("ERROR:")) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.replaceAll("ERROR: ", "")), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Sukses sebagai ${result!.toUpperCase()}!"), 
            backgroundColor: AppColors.neonGreenDark
          ),
        );
        // Simpan sesi login selama 30 hari
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('login_date', DateTime.now().toIso8601String());
        await prefs.setString('user_role', result);
        
        // Cek role untuk navigasi
        if (result == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
          );
        } else if (result == "user") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ClientMainLayout()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kita gunakan BaseLayout agar background titik-titik (grid) otomatis muncul
    return BaseLayout(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400), // Membatasi lebar form
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.card, // Warna latar abu-abu gelap solid
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER MFW ---
                Center(
                  child: Column(
                    children: [
                      Text(
                        "MFW",
                        style: GoogleFonts.orbitron(
                          color: AppColors.neonGreen,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic, // Sesuai gambar
                          shadows: [
                            Shadow(
                              color: AppColors.neonGreen.withOpacity(0.5),
                              blurRadius: 15,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "SYSTEM AUTHENTICATION",
                        style: GoogleFonts.orbitron(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // --- INPUT EMAIL ---
                Text(
                  "USERNAME / EMAIL",
                  style: GoogleFonts.orbitron(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField("Enter credentials", Icons.person, _emailController),
                const SizedBox(height: 20),

                // --- INPUT PASSWORD ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PASSWORD",
                      style: GoogleFonts.orbitron(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "FORGOT?",
                      style: GoogleFonts.orbitron(
                        color: AppColors.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField("••••••••", Icons.lock, _passwordController, isObscure: true),
                const SizedBox(height: 15),

                // --- REMEMBER DEVICE TOGGLE ---
                Row(
                  children: [
                    Switch(
                      value: _rememberDevice,
                      onChanged: (val) => setState(() => _rememberDevice = val),
                      activeColor: AppColors.background,
                      activeTrackColor: AppColors.textMuted,
                      inactiveThumbColor: AppColors.textMuted,
                      inactiveTrackColor: AppColors.background,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Remember device",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // --- LOGIN BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    // Style sudah diatur global di AppTheme, tapi kita tegaskan warnanya
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: AppColors.background, // Teks hitam
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "LOGIN",
                                style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.login, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 25),

                // --- QUICK LOGIN DIVIDER ---
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "OR QUICK LOGIN",
                        style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 20),

                // --- QUICK LOGIN ICONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickLoginBtn(Icons.gamepad),
                    _buildQuickLoginBtn(Icons.chat_bubble_outline),
                    _buildQuickLoginBtn(Icons.language),
                  ],
                ),
                const SizedBox(height: 30),

                // --- FOOTER REGISTER ---
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "NEW USER? ",
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      children: [
                        TextSpan(
                          text: "REGISTER HARDWARE",
                          style: TextStyle(
                            color: AppColors.neonGreenDark,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                
                // --- SEEDER SEMENTARA (Sesuai Permintaan) ---
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Menjalankan Seeder...")),
                      );
                      String result = await AdminSeeder.createInitialAdmin();
                      if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result),
                            backgroundColor: result.contains("Berhasil") ? AppColors.neonGreenDark : Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Run Admin Seeder (Debug)", 
                      style: TextStyle(color: Colors.redAccent, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Komponen Input Form
  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isObscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: AppColors.textWhite),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        hintText: hint,
        // Style border & fill color sudah di-handle oleh AppTheme (Global)
      ),
    );
  }

  // Komponen Tombol Kotak Quick Login
  Widget _buildQuickLoginBtn(IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.background, // Lebih gelap dari card
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textMuted, size: 20),
      ),
    );
  }
}