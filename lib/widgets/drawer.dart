import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({Key? key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
            ),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://www.shutterstock.com/image-illustration/healthy-lifestyle-icons-heart-yoga-260nw-1451061569.jpg', 
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          buildListTile(Icons.home, 'Home', () => GoRouter.of(context).go('/')),
          const SizedBox(height: 15),
          buildListTile(Icons.person, 'About Us', () => GoRouter.of(context).go('/about')),
        ],
      ),
    );
  }
  
  ListTile buildListTile(IconData icon, String title, Function()? onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 16)),
      onTap: onTap,
    );
  }
}
