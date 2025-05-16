import 'package:corelife/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inicio', 
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFFDEA4CE), // Rosa pastel principal
        elevation: 0, // Sin sombra para un look más moderno
        centerTitle: true, // Título centrado
        actions: [
          // Mantener espacio para posibles acciones futuras
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Acción futura: notificaciones
            },
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Container(
        // Agregamos un fondo con gradiente suave
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF6FA), // Rosa muy claro
              Colors.white,
            ],
          ),
        ),
        // Contenido principal
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono decorativo
              Icon(
                Icons.favorite,
                color: const Color(0xFFDEA4CE).withOpacity(0.7),
                size: 75,
              ),
              const SizedBox(height: 30),
              // Texto de bienvenida con estilo mejorado
              const Text(
                '¡Bienvenido a Corelife!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D3F5B), // Color púrpura oscuro para texto
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Subtítulo 
              Text(
                'Tu camino hacia hábitos saludables',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF6D3F5B).withOpacity(0.7),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 50),
              // Botón de cerrar sesión con estilo mejorado
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8AFA6), // Coral pastel para el botón de cierre
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0, // Sin sombra
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}