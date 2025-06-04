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
          'model': 'gpt-4',
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
        return _formatCatalystResponse(data['choices'][0]['message']['content'].toString().trim());
      } else {
        print('Error OpenAI: ${response.body}');
        return _formatCatalystResponse('Lo siento, no pude procesar tu mensaje en este momento.');
      }
    } catch (e) {
      print('Error en OpenAI Service: $e');
      return _formatCatalystResponse('Ocurrió un error. Por favor intenta de nuevo.');
    }
  }

  String _buildContextualPrompt(String userMessage, Map<String, dynamic> context) {
    final userName = context['usuario'] ?? context['userName'] ?? 'Usuario';
    final habitsCount = context['totalHabits'] ?? 0;
    final completionRate = context['weeklyCompletionRate'] ?? 0;
    final strugglingHabits = context['strugglingHabits'] ?? [];
    final bestHabits = context['bestHabits'] ?? [];
    final patterns = context['patterns'] ?? {};
    final bestTimes = context['bestTimes'] ?? {};

    return '''
ANÁLISIS DEL USUARIO:
👤 Nombre: $userName
📊 Estado Actual:
- Hábitos activos: $habitsCount
- Tasa de cumplimiento: ${completionRate.toStringAsFixed(1)}%
- Hábitos destacados: ${bestHabits.isEmpty ? 'Ninguno aún' : bestHabits.join(', ')}
- Áreas de mejora: ${strugglingHabits.isEmpty ? 'Ninguna identificada' : strugglingHabits.join(', ')}

PATRONES IDENTIFICADOS:
- Tendencia: ${patterns['improving'] == true ? '📈 Mejorando' : patterns['declining'] == true ? '📉 Necesita atención' : '➡️ Estable'}
- Mejor momento del día: ${patterns['preferredTime'] ?? 'No identificado'}
- Horarios óptimos: ${bestTimes.isEmpty ? 'En análisis' : bestTimes.entries.map((e) => "${e.key}: ${e.value}").join(', ')}

INTERACCIÓN ACTUAL: $userMessage

INSTRUCCIONES DE RESPUESTA:
1. Analiza el contexto completo del usuario
2. Genera una respuesta que:
   - Sea personalizada usando los datos disponibles
   - Incluya 2-3 opciones de acción entre [corchetes]
   - Sea motivadora y orientada a resultados
   - Use emojis apropiadamente para mejorar la comunicación
''';
  }

  String _getSystemPrompt() {
    return '''
Eres CoreLife Catalyst, un coach de bienestar personal proactivo y experto en análisis de hábitos.

PERSONALIDAD:
- Proactivo y observador: Identificas patrones y ofreces sugerencias específicas
- Empático pero directo: Entiendes las dificultades pero motivas a la acción
- Orientado a datos: Usas métricas específicas para fundamentar recomendaciones
- Motivador y positivo: Celebras logros y animas durante los desafíos

CAPACIDADES:
1. Análisis de Patrones:
   - Evalúas tendencias en el cumplimiento de hábitos
   - Identificas horarios óptimos y patrones de éxito
   - Detectas áreas de mejora y oportunidades

2. Coaching Personalizado:
   - Sugieres ajustes basados en datos reales
   - Propones modificaciones graduales y alcanzables
   - Ofreces estrategias para superar obstáculos

3. Motivación Contextual:
   - Celebras logros con datos específicos
   - Proporcionas recordatorios estratégicos
   - Anticipas desafíos y ofreces soluciones preventivas

REGLAS DE INTERACCIÓN:
1. FORMATO DE RESPUESTA:
   - Mensaje principal: Corto y directo (2-3 oraciones máximo)
   - Opciones: 2-3 alternativas entre [corchetes]
   - Emojis: Usar cuando sea apropiado para mejorar comprensión

2. CONTENIDO:
   - Siempre incluir al menos un dato específico del usuario
   - Ofrecer opciones concretas y accionables
   - Mantener un tono positivo incluso al señalar áreas de mejora

3. ENFOQUE:
   - Priorizar acciones pequeñas y alcanzables
   - Celebrar cualquier progreso, sin importar lo pequeño
   - Ofrecer alternativas cuando se detecten dificultades
''';
  }

  String _formatCatalystResponse(String response) {
    if (response.contains('[') && response.contains(']')) {
      return response;
    }
    
    final isPositive = response.contains('¡') || 
                      response.contains('excelente') || 
                      response.contains('bien') ||
                      response.contains('felicidades');
    
    final isQuestion = response.contains('?');
    
    if (isPositive) {
      return '''
$response

[✨ ¡Genial!] [📈 Ver progreso] [🎯 Siguiente meta]
''';
    } else if (isQuestion) {
      return '''
$response

[👍 Sí, me interesa] [🤔 Necesito más info] [⏳ Otro momento]
''';
    } else {
      return '''
$response

[✅ Entendido] [💡 ¿Cómo mejorar?] [📊 Ver detalles]
''';
    }
  }
}