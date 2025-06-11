import 'package:corelife/screens/habits_screen.dart';
import 'package:corelife/screens/metrics_screen.dart';
import 'package:corelife/screens/confirmation_screen.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/chatbot_screen.dart';
import '../screens/paypal_payment_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        path: '/metrics',
        builder: (context, state) => const MetricsScreen(),
      ),
      GoRoute(
        path: '/paypal',
        builder: (context, state) => const PayPalPaymentScreen(),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) => const ConfirmationScreen(),
      ),
    ],
    initialLocation: '/login',
  );
}
