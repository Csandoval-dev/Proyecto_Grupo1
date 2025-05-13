import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Comentamos la inicialización para evitar la advertencia
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    } on FirebaseAuthException catch (e) {
      // Manejo específico de errores de Firebase Auth
      print('Error de Firebase Auth al registrarse: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error general al registrarse: $e');
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
      print('Inicio de sesión exitoso: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Manejo específico de errores de Firebase Auth
      print('Error de Firebase Auth al iniciar sesión: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error general al iniciar sesión: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      // Si el usuario inició sesión con Google, también cerramos esa sesión
      // Ya que comentamos la inicialización, también comentamos esta parte
      // if (await _googleSignIn.isSignedIn()) {
      //   await _googleSignIn.signOut();
      // }
      await _auth.signOut();
      print('Sesión cerrada correctamente');
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Iniciar sesión con Google (mantenemos la función pero por ahora devuelve null)
  Future<User?> signInWithGoogle() async {
    // Por ahora, esta función no hace nada
    print('Función de inicio de sesión con Google no implementada');
    return null;
  }

  // Obtener el usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Verificar si el usuario ya está autenticado
  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }
}