import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla para manejar mejor el layout
    final Size screenSize = MediaQuery.of(context).size;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Drawer(
      backgroundColor: const Color(0xFFFFF6FA), // Fondo pastel más claro y suave
      child: SafeArea( // Agregamos SafeArea para evitar overflow con la barra de estado
        child: Column(
          children: [
            _buildDrawerHeader(context, statusBarHeight),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(), // Efecto de rebote al scrollear
                children: <Widget>[
                  const SizedBox(height: 10),
                  buildListTile(context, Icons.home_rounded, 'Inicio', () => GoRouter.of(context).go('/')),
                  buildListTile(context, FontAwesomeIcons.listCheck, 'Hábitos', () => GoRouter.of(context).go('/habits')),
                  buildListTile(context, FontAwesomeIcons.chartLine, 'Métricas', () => GoRouter.of(context).go('/metrics')),
                  buildListTile(context, FontAwesomeIcons.heartPulse, 'CoreLife', () => GoRouter.of(context).go('/chatbot')),
                  buildListTile(context, Icons.people_alt_rounded, 'About Us', () => GoRouter.of(context).go('/about')),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Divider(color: Color(0xFFE6BFD9), thickness: 1.5),
                  ),
                  buildListTile(context, Icons.settings_rounded, 'Configuración', () => GoRouter.of(context).go('/settings')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerHeader(BuildContext context, double statusBarHeight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFC8DD), // Rosa pastel más vibrante
            Color(0xFFBFB3E0), // Lila pastel más atractivo
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Color(0xFFDEA4CE), // Color icono rosa más vibrante
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Usuario",
            style: TextStyle(
              color: Color(0xFF6D3F5B), // Color más profundo para mejor contraste
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget buildListTile(BuildContext context, IconData icon, String title, Function()? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        leading: Icon(
          icon, 
          color: const Color(0xFFDEA4CE), // Color de icono más vibrante
          size: 24,
        ),
        title: Text(
          title, 
          style: const TextStyle(
            color: Color(0xFF6D3F5B), // Color de texto más oscuro para mejor legibilidad
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        hoverColor: const Color(0xFFFFC8DD).withOpacity(0.3),
        // Forma más redondeada para cada item
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        // Agregamos un color para el efecto tap
        tileColor: Colors.transparent,
        selectedTileColor: const Color(0xFFFFC8DD).withOpacity(0.15),
      ),
    );
  }
}