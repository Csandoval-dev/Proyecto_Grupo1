import 'package:corelife/screens/habits_screen.dart';
import 'package:corelife/screens/metrics_screen.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/chatbot_screen.dart';



class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
       path: '/chatbot',
        builder: (context, state) => const ChatbotScreen(),
),
GoRoute(
        path: '/habits', // Esta es la ruta que usarás para navegar
        builder: (context, state) => const HabitsScreen(), // Aquí instancias tu pantalla
      ),
      GoRoute(
        path: '/metrics', // Esta es la ruta que usarás para navegar
        builder: (context, state) => const MetricsScreen (), // Aquí instancias tu pantalla
      ),
    ],
    initialLocation: '/login',
  );
}
