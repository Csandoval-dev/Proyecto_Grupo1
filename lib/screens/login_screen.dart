import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _loginWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          _showErrorSnackBar("Error al iniciar sesión. Revisa tus credenciales.");
        }
      } catch (e) {
        _showErrorSnackBar("Error: ${e.toString()}");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        _showErrorSnackBar("Error al iniciar sesión con Google");
      }
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40),
                  // Encabezado de bienvenida
                  Center(
                    child: Text(
                      "¡BIENVENIDO!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Imagen o ilustración
                  Center(
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEDE7F6),
                      ),
                      child: Center(
                        // Aquí puedes agregar tu propia imagen
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  // Campo de correo electrónico
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Color(0xFF6A1B9A)),
                        hintText: 'Correo electrónico',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa tu correo electrónico';
                        }
                        if (!value.contains('@')) {
                          return 'Ingresa un correo electrónico válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  // Campo de contraseña
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF6A1B9A)),
                        hintText: 'Contraseña',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Color(0xFF6A1B9A),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa tu contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  // Enlace de olvidaste tu contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Implementación para recuperar contraseña
                      },
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Botón de inicio de sesión
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6A1B9A),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  SizedBox(height: 20),
                  // Separador "O"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.grey[300]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'O',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.grey[300]),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Botones de inicio de sesión con redes sociales
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialLoginButton(
                        onPressed: _loginWithGoogle,
                        icon: Icons.g_mobiledata,
                      ),
                      SizedBox(width: 16),
                      _socialLoginButton(
                        onPressed: () {},
                        icon: Icons.facebook,
                      ),
                      SizedBox(width: 16),
                      _socialLoginButton(
                        onPressed: () {},
                        icon: Icons.apple,
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  // Enlace para registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes una cuenta? ',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        ),
                        child: Text(
                          'Regístrate',
                          style: TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialLoginButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 30,
            color: Color(0xFF6A1B9A),
          ),
        ),
      ),
    );
  }
}