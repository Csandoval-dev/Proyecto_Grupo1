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
        return _formatCatalystResponse(
          data['choices'][0]['message']['content'].toString().trim(),
          userContext['currentHabit'] != null,
        );
      } else {
        print('Error OpenAI: ${response.body}');
        throw Exception('Error en la respuesta de OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en OpenAI Service: $e');
      return _formatCatalystResponse(
        'Lo siento, hubo un error al procesar tu mensaje. ¿Podrías intentarlo de nuevo?',
        false,
      );
    }
  }

  String _buildContextualPrompt(String userMessage, Map<String, dynamic> context) {
    final userName = context['userName'] ?? 'Usuario';
    final currentHabit = context['currentHabit'];
    final habitMetrics = context['habitMetrics'];
    final habits = context['habitsList'] as List<dynamic>? ?? [];
    
    String prompt = '''
ANÁLISIS DEL USUARIO:
👤 Nombre: $userName
📊 Estado General:
- Hábitos activos: ${habits.length}
''';

    // Agregar contexto específico del hábito si está seleccionado
    if (currentHabit != null) {
      prompt += '''
🎯 HÁBITO EN FOCO:
- Nombre: ${currentHabit['name']}
- Descripción: ${currentHabit['description'] ?? 'Sin descripción'}
- Categoría: ${currentHabit['category'] ?? 'General'}
''';

      if (habitMetrics != null) {
        final completionRate = habitMetrics['completionRate'] ?? 0;
        final totalDone = habitMetrics['totalDone'] ?? 0;
        final totalMissed = habitMetrics['totalMissed'] ?? 0;
        final weeklyData = habitMetrics['weeklyData'] ?? 0;

        prompt += '''
📈 MÉTRICAS DEL HÁBITO:
- Tasa de cumplimiento: $completionRate%
- Completados: $totalDone
- Perdidos: $totalMissed
- Semanas registradas: $weeklyData

${_getHabitAnalysis(completionRate, totalDone, totalMissed)}
''';
      }

      // Agregar patrones identificados si existen
      if (context['patterns'] != null) {
        final patterns = context['patterns'] as Map<String, dynamic>;
        prompt += '''
🔍 PATRONES IDENTIFICADOS:
- Tendencia: ${_getProgressTrend(patterns)}
- Mejor horario: ${patterns['preferredTime'] ?? 'No identificado'}
''';
      }
    } else if (habits.isNotEmpty) {
      prompt += '''
📋 HÁBITOS DISPONIBLES:
${habits.asMap().entries.map((e) => "- ${e.key + 1}. ${e.value['name']}").join('\n')}

💡 Tip: Puedes seleccionar un hábito por su número o nombre.
''';
    }

    prompt += '''

💬 MENSAJE ACTUAL: $userMessage

INSTRUCCIONES DE RESPUESTA:
1. ${currentHabit != null 
    ? 'Enfócate en el hábito seleccionado y sus métricas'
    : 'Ayuda al usuario a seleccionar o gestionar sus hábitos'}
2. Genera una respuesta que:
   - Sea personalizada y específica al contexto
   - Use datos concretos cuando estén disponibles
   - Incluya 2-3 opciones de acción entre [corchetes]
   - Use emojis apropiadamente
''';

    return prompt;
  }

  String _getHabitAnalysis(int completionRate, int totalDone, int totalMissed) {
    if (totalDone + totalMissed == 0) {
      return '⚠️ No hay suficientes datos para análisis';
    }

    if (completionRate >= 80) {
      return '🌟 EXCELENTE DESEMPEÑO: Mantén este nivel de compromiso.';
    } else if (completionRate >= 60) {
      return '👍 BUEN PROGRESO: Vas por buen camino, pero hay espacio para mejorar.';
    } else if (completionRate >= 40) {
      return '💪 ÁREA DE OPORTUNIDAD: Con pequeños ajustes puedes mejorar significativamente.';
    } else {
      return '❗ NECESITA ATENCIÓN: Identifiquemos juntos los obstáculos y creemos un plan.';
    }
  }

  String _getProgressTrend(Map<String, dynamic> patterns) {
    if (patterns['improving'] == true) {
      return '📈 En mejora';
    } else if (patterns['declining'] == true) {
      return '📉 Necesita atención';
    }
    return '➡️ Estable';
  }

  String _getSystemPrompt() {
    return '''
Eres CoreLife Catalyst, un coach de bienestar personal experto en análisis de hábitos.

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

  String _formatCatalystResponse(String response, bool hasHabitContext) {
    if (response.contains('[') && response.contains(']')) {
      return response;
    }
    
    final isPositive = response.contains('¡') || 
                      response.contains('excelente') || 
                      response.contains('bien') ||
                      response.contains('felicidades');
    
    final isQuestion = response.contains('?');
    
    if (hasHabitContext) {
      if (isPositive) {
        return '''
$response

[✨ ¡Excelente!] [📊 Ver detalles] [🎯 Ajustar meta]
''';
      } else if (isQuestion) {
        return '''
$response

[👍 Sí, adelante] [💡 Más información] [🔄 Cambiar hábito]
''';
      } else {
        return '''
$response

[✅ Entendido] [📈 Ver progreso] [❓ Necesito ayuda]
''';
      }
    } else {
      if (isPositive) {
        return '''
$response

[✨ ¡Genial!] [📋 Ver hábitos] [➕ Nuevo hábito]
''';
      } else if (isQuestion) {
        return '''
$response

[👍 Sí, me interesa] [🤔 Más detalles] [⏳ Después]
''';
      } else {
        return '''
$response

[✅ Entendido] [💡 Sugerencias] [📊 Ver resumen]
''';
      }
    }
  }
}