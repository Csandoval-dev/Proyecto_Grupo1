import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registrar con email y contraseña
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar datos del usuario en Firestore
      await _firestore.collection('Usuarios').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': DateTime.now(),
      });

      return userCredential.user;
    } catch (e) {
      print('Error al registrarse: $e');
      return null;
    }
  }

  // Iniciar sesión con email y contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Sesión cerrada correctamente');
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Obtener el usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Verificar si el usuario ya está autenticado
  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  signInWithGoogle() {}
}
