import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY no está configurada en el archivo .env');
    }
    return key;
  }

  Future<String> sendMessage({
    required String userMessage,
    required Map<String, dynamic> userContext,
  }) async {
    try {
      final prompt = _buildContextualPrompt(userMessage, userContext);
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        return 'Lo siento, no pude procesar tu mensaje en este momento.';
      }
    } catch (e) {
      print('Error en OpenAI Service: $e');
      return 'Ocurrió un error. Por favor intenta de nuevo.';
    }
  }

  String _buildContextualPrompt(String userMessage, Map<String, dynamic> context) {
    final userName = context['userName'] ?? 'Usuario';
    final habitsCount = context['totalHabits'] ?? 0;
    final completionRate = context['weeklyCompletionRate'] ?? 0;
    final strugglingHabits = context['strugglingHabits'] ?? [];
    final bestHabits = context['bestHabits'] ?? [];

    return '''
CONTEXTO DEL USUARIO:
- Nombre: $userName
- Total de hábitos activos: $habitsCount
- Tasa de cumplimiento semanal: ${completionRate.toStringAsFixed(1)}%
- Hábitos con dificultades: ${strugglingHabits.join(', ')}
- Mejores hábitos: ${bestHabits.join(', ')}

PREGUNTA DEL USUARIO: $userMessage

Responde como un coach personal motivador y empático. Usa el nombre del usuario cuando sea apropiado.
''';
  }

  String _getSystemPrompt() {
    return '''
Eres CoreLife AI, un asistente personal especializado en hábitos saludables.

PERSONALIDAD:
- Motivador pero realista
- Empático y comprensivo
- Ofreces consejos prácticos
- Usas un tono amigable y cercano

CAPACIDADES:
- Analizar patrones de hábitos
- Dar consejos personalizados
- Motivar al usuario
- Sugerir mejoras
- Detectar problemas y ofrecer soluciones

REGLAS:
- Mantén respuestas cortas (máximo 2-3 oraciones)
- Sé específico con los datos del usuario
- Ofrece una acción concreta cuando sea apropiado
- Si no tienes suficiente contexto, pregunta más detalles
''';
  }
}