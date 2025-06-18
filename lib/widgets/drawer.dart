import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildProfileSection(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildMainMenuSection(context),
                    const SizedBox(height: 24),
                    _buildSecondaryMenuSection(context),
                    const SizedBox(height: 24),
                    _buildSettingsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6200EA),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF6200EA),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Csandoval-dev',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Desarrollador',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'PRINCIPAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context: context,
          icon: Icons.home_rounded,
          title: 'Inicio',
          route: '/home',
          isFirst: true,
        ),
        _buildMenuItem(
          context: context,
          icon: FontAwesomeIcons.listCheck,
          title: 'Hábitos',
          route: '/habits',
        ),
        _buildMenuItem(
          context: context,
          icon: FontAwesomeIcons.chartLine,
          title: 'Métricas',
          route: '/metrics',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildSecondaryMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'SERVICIOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context: context,
          icon: FontAwesomeIcons.heartPulse,
          title: 'CoreLife',
          route: '/chatbot',
          isFirst: true,
        ),
        _buildMenuItem(
          context: context,
          icon: FontAwesomeIcons.crown,
          title: 'Premium',
          route: '/paypal',
          isLast: true,
          isPremium: true,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'PREFERENCIAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context: context,
          icon: Icons.settings_rounded,
          title: 'Configuración',
          route: '/settings',
          isFirst: true,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    bool isFirst = false,
    bool isLast = false,
    bool isPremium = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => GoRouter.of(context).go(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              top: isFirst ? BorderSide(color: Colors.grey.withOpacity(0.1)) : BorderSide.none,
              bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPremium 
                      ? const Color(0xFFFFC107).withOpacity(0.1)
                      : const Color(0xFF6200EA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isPremium ? const Color(0xFFFFA000) : const Color(0xFF6200EA),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFA000),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}