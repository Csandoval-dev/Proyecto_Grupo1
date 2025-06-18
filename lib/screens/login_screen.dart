import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  // Instancia del servicio de autenticación
  final AuthService _authService = AuthService();
  
  // Mensaje de error
  String? _errorMessage;

  @override
  void dispose() {
    // Limpiamos los controladores para evitar memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para iniciar sesión
  Future<void> _login() async {
    // Validamos el formulario
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          // Navegación exitosa a la página principal
          context.go('/home');
        } else {
          setState(() {
            _errorMessage = 'No se pudo iniciar sesión. Verifica tus credenciales.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla para responsive design
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20.0 : 24.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 30 : 40),
                  _buildLoginForm(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 24 : 30),
                  _buildDivider(),
                  SizedBox(height: isSmallScreen ? 24 : 30),
                  _buildSocialButtons(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  _buildSignUpLink(),
                ],
              ).animate().fadeIn(duration: 600.ms),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isSmallScreen) {
    return Column(
      children: [
        // Aquí deberías usar Image.asset para cargar logo.png
        Container(
          width: isSmallScreen ? 100 : 120,
          height: isSmallScreen ? 100 : 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF007F), Color(0xFFFF00FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF007F).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ).animate()
          .scale(duration: 600.ms, curve: Curves.easeOut)
          .then()
          .shimmer(duration: 1200.ms),
        SizedBox(height: isSmallScreen ? 16 : 20),
        Text(
          "CoreLife",
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 28 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slide(),
      ],
    );
  }

  Widget _buildLoginForm(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
           Text(
  "Bienvenido",
  textAlign: TextAlign.center,
  style: GoogleFonts.poppins(
    fontSize: isSmallScreen ? 22 : 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildTextField(
              controller: _emailController,
              hintText: "Correo electrónico",
              icon: FontAwesomeIcons.envelope,
              isPassword: false,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: isSmallScreen ? 14 : 16),
            _buildTextField(
              controller: _passwordController,
              hintText: "Contraseña",
              icon: FontAwesomeIcons.lock,
              isPassword: true,
            ),
            // Mostrar mensaje de error si existe
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "¿Olvidaste tu contraseña?",
                  style: TextStyle(
                    color: const Color(0xFFFF007F),
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildLoginButton(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isSmallScreen) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF007F),
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20, 
              width: 20, 
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FontAwesomeIcons.rightToBracket, size: 18),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Text(
                  "Iniciar sesión",
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .scale(duration: 300.ms);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isPassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFFF007F), size: 20),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF3C3C3C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? FontAwesomeIcons.eye
                      : FontAwesomeIcons.eyeSlash,
                  color: const Color(0xFFFF007F),
                  size: 18,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        // Validación adicional para el correo electrónico
        if (hintText == "Correo electrónico" && !value.contains('@')) {
          return 'Ingresa un correo electrónico válido';
        }
        // Validación de longitud para la contraseña
        if (hintText == "Contraseña" && value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "O continúa con",
            style: TextStyle(color: Colors.white54),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }

  Widget _buildSocialButtons(bool isSmallScreen) {
    final double buttonSize = isSmallScreen ? 45 : 55;
    final double iconSize = isSmallScreen ? 22 : 25;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cambiado a color blanco para el botón de Google
        _buildSocialButton(
          icon: FontAwesomeIcons.google,
          color: Colors.white, // Cambiado de rojo a blanco
          size: buttonSize,
          iconSize: iconSize,
          onPressed: () {
            // Por ahora sólo visual
          },
          iconColor: Colors.red, // Color del icono para que sea visible en fondo blanco
        ),
        SizedBox(width: isSmallScreen ? 16 : 20),
        _buildSocialButton(
          icon: FontAwesomeIcons.facebook,
          color: const Color(0xFF4267B2),
          size: buttonSize,
          iconSize: iconSize,
          onPressed: () {
            // Por ahora sólo visual
          },
        ),
        SizedBox(width: isSmallScreen ? 16 : 20),
        // Cambiado por el ícono de GitHub
        _buildSocialButton(
          icon: FontAwesomeIcons.github, // Cambiado a GitHub
          color: Colors.black, // Color negro típico de GitHub
          size: buttonSize,
          iconSize: iconSize,
          onPressed: () {
            // Por ahora sólo visual
          },
          iconColor: Colors.white, // Color del icono para que sea visible en fondo negro
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size/2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    ).animate()
      .scale(duration: 300.ms)
      .shimmer(duration: 1200.ms);
  }

  Widget _buildSignUpLink() {
    return TextButton(
      onPressed: () => context.go('/register'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "¿No tienes cuenta? ",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          Text(
            "Regístrate",
            style: GoogleFonts.poppins(
              color: const Color(0xFFFF007F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}