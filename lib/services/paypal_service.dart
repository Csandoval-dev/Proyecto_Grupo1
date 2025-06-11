import 'dart:convert';
import 'package:http/http.dart' as http;

class PayPalService {
  // Reemplaza estos valores con tus credenciales reales de PayPal (Sandbox o Live)
  final String clientId = 'ATvGDvq8eq3OwbNa9H_O2rkSwNpZI_WmL9S2O3-WwiAQ5qE3JarSMpyBfM0mseGjZKklLDbMqxELK_tz';
  final String secret = 'EKCiO-la1EYB3A-P4DDGG3J8xJjLEVvl9CNYH9IJMxE1bt-BxcwaHXbU0yA5W4XU_klOqNHWFddKC8l3';
  final String domain = 'https://api-m.sandbox.paypal.com'; // Cambia a live si usas producción

  /// Obtiene el token de acceso OAuth2 desde PayPal
  Future<String?> getAccessToken() async {
    final basicAuth = base64Encode(utf8.encode('$clientId:$secret'));

    try {
      final response = await http.post(
        Uri.parse('$domain/v1/oauth2/token'),
        headers: {
          'Authorization': 'Basic $basicAuth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['access_token'];
      } else {
        debugLog('Error al obtener token: ${response.body}');
        return null;
      }
    } catch (e) {
      debugLog('Excepción al obtener token: $e');
      return null;
    }
  }

  /// Crea una suscripción y devuelve el enlace de aprobación
  Future<String?> createSubscription(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$domain/v1/billing/subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "plan_id": "P-1K3983531R123423ANBB5CIA", // Este plan lo configuras en el panel de PayPal
          "application_context": {
            "brand_name": "CorelifeApp",
            "user_action": "SUBSCRIBE_NOW",
            "return_url": "https://example.com/return", // Personaliza según tu backend
            "cancel_url": "https://example.com/cancel"
          }
        }),
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final links = body['links'] as List<dynamic>;
        final approveLink = links.firstWhere(
          (link) => link['rel'] == 'approve',
          orElse: () => null,
        );
        return approveLink?['href'];
      } else {
        debugLog('Error al crear suscripción: ${response.body}');
        return null;
      }
    } catch (e) {
      debugLog('Excepción al crear suscripción: $e');
      return null;
    }
  }

  /// Reemplazo de print por función de log (opcional para producción)
  void debugLog(String message) {
    // Puedes usar paquete `logger` en producción
    // ignore: avoid_print
    print('[PayPalService] $message');
  }
}
