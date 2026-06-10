import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../seeder/admin_seeder.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/base_layout.dart';
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
  bool _rememberDevice = true;

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('login_date', DateTime.now().toIso8601String());
        await prefs.setString('user_role', result);
        
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
    return BaseLayout(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withOpacity(0.04),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
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
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: AppColors.neonGreen.withOpacity(0.4),
                              blurRadius: 20,
                            ),
                            Shadow(
                              color: AppColors.neonGreen.withOpacity(0.15),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "SYSTEM AUTHENTICATION",
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // --- INPUT EMAIL ---
                Text(
                  "USERNAME / EMAIL",
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField("Enter credentials", Icons.person_outline_rounded, _emailController),
                const SizedBox(height: 18),

                // --- INPUT PASSWORD ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PASSWORD",
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "FORGOT?",
                      style: GoogleFonts.inter(
                        color: AppColors.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField("••••••••", Icons.lock_outline_rounded, _passwordController, isObscure: true),
                const SizedBox(height: 14),

                // --- REMEMBER DEVICE TOGGLE ---
                Row(
                  children: [
                    Switch(
                      value: _rememberDevice,
                      onChanged: (val) => setState(() => _rememberDevice = val),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Remember device",
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w400),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // --- LOGIN BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      shadowColor: AppColors.neonGreen.withOpacity(0.4),
                      elevation: 8,
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
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 22),

                // --- QUICK LOGIN DIVIDER ---
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "OR QUICK LOGIN",
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 18),

                // --- QUICK LOGIN ICONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickLoginBtn(Icons.gamepad_outlined),
                    _buildQuickLoginBtn(Icons.chat_bubble_outline_rounded),
                    _buildQuickLoginBtn(Icons.language),
                  ],
                ),
                const SizedBox(height: 26),

                // --- FOOTER REGISTER ---
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "NEW USER? ",
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w400),
                      children: [
                        TextSpan(
                          text: "REGISTER HARDWARE",
                          style: GoogleFonts.inter(
                            color: AppColors.neonGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.neonGreen.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                // --- SEEDER ---
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
                    child: Text(
                      "Run Admin Seeder (Debug)", 
                      style: GoogleFonts.inter(color: Colors.redAccent.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w400),
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

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isObscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }

  Widget _buildQuickLoginBtn(IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textMuted, size: 18),
      ),
    );
  }
}
