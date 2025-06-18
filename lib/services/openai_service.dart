import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

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
          'max_tokens': 300, // Reducido para respuestas más concisas
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _formatCatalystResponse(
          data['choices'][0]['message']['content'].toString().trim(),
          userContext,
        );
      } else {
        print('Error OpenAI: ${response.body}');
        throw Exception('Error en la respuesta de OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en OpenAI Service: $e');
      return 'Lo siento, hubo un error al procesar tu mensaje. ¿Podrías intentarlo de nuevo? No te desanimes, cada obstáculo es una oportunidad para crecer 💪\n\n[🔄] Reintentar\n[❓] Ayuda\n[💬] Contacto';
    }
  }

  String _buildContextualPrompt(String userMessage, Map<String, dynamic> context) {
    final currentDateTime = DateTime.now().toUtc();
    final formattedDateTime = 
        "${currentDateTime.toIso8601String().split('.')[0]}Z";

    final userName = context['userName'] ?? 'Usuario';
    final currentHabit = context['currentHabit'];
    final habitMetrics = context['habitMetrics'];
    final previousContext = context['previousContext'] as Map<String, dynamic>?;
    final habits = context['habitsList'] as List<dynamic>? ?? [];
    
    String prompt = '''ANÁLISIS DEL USUARIO Y CONTEXTO:
👤 Usuario: $userName
📅 Fecha: $formattedDateTime
💭 Último tema: ${previousContext?['lastTopic'] ?? 'Ninguno'}
📊 Estado: ${habits.length} hábitos activos

''';

    final selectedOptions = previousContext?['selectedOptions'] as List<String>? ?? [];
    if (selectedOptions.isNotEmpty) {
      prompt += '🔍 Últimas selecciones: ${selectedOptions.join(", ")}\n';
    }

    if (currentHabit != null) {
      prompt += '''🎯 HÁBITO ACTUAL:
Nombre: ${currentHabit['name']}
Categoría: ${currentHabit['category'] ?? 'General'}
''';

      if (habitMetrics != null && habitMetrics['hasData'] == true) {
        final patterns = habitMetrics['patterns'] as Map<String, dynamic>;
        final weeklyData = habitMetrics['weeklyData'] as List;
        
        prompt += '''
📈 MÉTRICAS CLAVE:
• Completados esta semana: ${habitMetrics['totalDone']}/${weeklyData.length}
• Tasa de éxito: ${habitMetrics['completionRate']}%
• Racha actual: ${patterns['currentStreak']} días
• Tendencia: ${_analyzeTrend(weeklyData)}

🎯 PATRONES:
• Mejor día: ${patterns['bestDay']} (${patterns['bestDayRate']}%)
• Día desafiante: ${patterns['worstDay']} (${patterns['worstDayRate']}%)
''';
      }
    }

    prompt += '''\n💭 MENSAJE DEL USUARIO: $userMessage

🎯 INSTRUCCIONES PARA RESPUESTA OPTIMIZADA:
1. Respuesta concisa: 120-150 palabras máximo
2. Motivación auténtica como elemento central
3. Si hay hábito con métricas: mostrar estadística compacta (ej: "Esta semana: 4/7 días ✅")
4. Usar formato de texto apropiado para plataforma
5. Incluir 3 opciones de acción específicas
6. OBLIGATORIO: Incluir [📊] Ver detalles si hay métricas disponibles
7. Mantener tono cálido y motivador
8. Terminar con reflexión o pregunta que conecte emocionalmente''';

    return prompt;
  }

  String _formatCatalystResponse(String response, Map<String, dynamic> context) {
    final currentHabit = context['currentHabit'];
    final habitMetrics = context['habitMetrics'];
    
    String cleanedResponse = _cleanAIResponse(response);
    
    if (currentHabit != null && habitMetrics?['hasData'] == true) {
      return _formatHabitResponse(currentHabit, habitMetrics, cleanedResponse);
    } else {
      return _formatGeneralResponse(cleanedResponse, context);
    }
  }

  String _cleanAIResponse(String response) {
    // Limpiar formato excesivo
    response = response.replaceAll(RegExp(r'\*{3,}'), _getBoldFormat());
    response = response.replaceAll(RegExp(r'#{1,6}\s*'), '');
    response = response.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Arreglar negritas según plataforma
    if (kIsWeb) {
      response = response.replaceAll('**', '');
      response = response.replaceAll(RegExp(r'\*([^*]+)\*'), '<b>\$1</b>');
    }
    
    return response.trim();
  }

  String _getBoldFormat() {
    return kIsWeb ? '' : '**';
  }

  String _formatHabitResponse(
    Map<String, dynamic> habit,
    Map<String, dynamic> metrics,
    String response
  ) {
    final patterns = metrics['patterns'] as Map<String, dynamic>;
    final weeklyData = metrics['weeklyData'] as List;
    
    // Estadística compacta
    final weeklyStats = 'Esta semana: ${metrics['totalDone']}/${weeklyData.length} días ✅';
    
    // Motivación contextual
    String motivationalNote = _generateMotivationalNote(metrics);
    
    // Formato optimizado
    final boldStart = kIsWeb ? '<b>' : '**';
    final boldEnd = kIsWeb ? '</b>' : '**';
    
    String formattedResponse = '''${boldStart}🎯 ${habit['name']}${boldEnd}

$weeklyStats | Racha: ${patterns['currentStreak']} días ⚡
Tasa de éxito: ${boldStart}${metrics['completionRate']}%${boldEnd} | Tendencia: ${_analyzeTrend(metrics['weeklyData'])}

$response

$motivationalNote''';

    return _addContextualOptions(formattedResponse, metrics, true);
  }

  String _formatGeneralResponse(String response, Map<String, dynamic> context) {
    final hasHabits = (context['habitsList'] as List?)?.isNotEmpty ?? false;
    final habitCount = (context['habitsList'] as List?)?.length ?? 0;
    
    String contextualNote = '';
    if (hasHabits) {
      contextualNote = '\n✨ *Tienes $habitCount hábito${habitCount > 1 ? 's' : ''} activo${habitCount > 1 ? 's' : ''} - ¡cada paso cuenta!*';
    } else {
      contextualNote = '\n🚀 *Todo gran cambio comienza con un pequeño paso*';
    }
    
    String formattedResponse = '''$response$contextualNote''';
    
    return _addContextualOptions(formattedResponse, null, false);
  }

  String _addContextualOptions(String response, Map<String, dynamic>? metrics, bool hasHabitMetrics) {
    // Determinar contexto para opciones inteligentes
    final isPositive = response.contains('¡') || 
                      response.toLowerCase().contains('excelente') || 
                      response.toLowerCase().contains('bien') ||
                      response.toLowerCase().contains('genial');
    
    final isQuestion = response.contains('?');
    
    String options = '\n\n';
    
    if (hasHabitMetrics) {
      final completionRate = metrics?['completionRate'] as double? ?? 0;
      final currentStreak = metrics?['patterns']['currentStreak'] as int? ?? 0;
      
      if (completionRate >= 80 || currentStreak >= 7) {
        options += '[🎯] Aumentar desafío\n[📊] Ver detalles\n[🔄] Nuevo hábito';
      } else if (completionRate >= 60) {
        options += '[📈] Consejos para mejorar\n[📊] Ver detalles\n[🎯] Ajustar meta';
      } else {
        options += '[🆘] Necesito apoyo\n[📊] Ver detalles\n[📋] Crear plan';
      }
    } else {
      if (isPositive) {
        options += '[✨] ¡Empezar ahora!\n[💡] Ideas de hábitos\n[📚] Aprender más';
      } else if (isQuestion) {
        options += '[👍] Sí, adelante\n[🤔] Más información\n[❓] Otras opciones';
      } else {
        options += '[🎯] Elegir hábito\n[💡] Sugerencias\n[❓] ¿Cómo funciona?';
      }
    }
    
    return response + options;
  }

  String _generateMotivationalNote(Map<String, dynamic> metrics) {
    final completionRate = metrics['completionRate'] as double;
    final currentStreak = metrics['patterns']['currentStreak'] as int;
    final totalDone = metrics['totalDone'] as int;
    
    if (currentStreak >= 7) {
      return '🔥 *¡$currentStreak días seguidos! Tu constancia es verdaderamente inspiradora.*';
    } else if (completionRate >= 80) {
      return '🌟 *Con ${completionRate.round()}% de éxito, estás construyendo algo extraordinario.*';
    } else if (completionRate >= 60) {
      return '💪 *Vas por buen camino. Cada día completado es una victoria personal.*';
    } else if (totalDone > 0) {
      return '✨ *Cada esfuerzo cuenta. No subestimes el poder de los pequeños pasos.*';
    } else {
      return '🎯 *Un nuevo día, una nueva oportunidad para brillar.*';
    }
  }

  String _analyzeTrend(List<dynamic> weeklyData) {
    if (weeklyData.isEmpty) return 'Sin datos';
    
    try {
      var completionRates = weeklyData.map((day) {
        final done = (day['done'] ?? 0) as int;
        final missed = (day['missed'] ?? 0) as int;
        final total = done + missed;
        return total > 0 ? (done / total) * 100 : 0.0;
      }).toList();

      if (completionRates.length >= 3) {
        final recent = completionRates.take(3).reduce((a, b) => a + b) / 3;
        final older = completionRates.skip(3).take(3).isNotEmpty 
            ? completionRates.skip(3).take(3).reduce((a, b) => a + b) / 
              completionRates.skip(3).take(3).length
            : recent;
        
        if (recent > older + 15) return '📈 Mejorando';
        if (recent > older + 5) return '📈 Progreso';
        if (recent < older - 15) return '📉 Atención';
        if (recent < older - 5) return '📉 Bajando';
      }
      
      return '➡️ Estable';
    } catch (e) {
      return 'Variable';
    }
  }

  String _getSystemPrompt() {
    return '''Eres CoreLife Catalyst, un coach de hábitos experto en motivación auténtica y análisis conductual.

PERSONALIDAD CORE:
• Motivador genuino: La motivación es tu fuerza principal, siempre auténtica y cálida
• Analítico pero humano: Datos al servicio de la conexión emocional
• Conciso pero completo: Respuestas de 120-150 palabras máximo
• Orientado a la acción: Siempre ofreces caminos claros hacia adelante

ESTRUCTURA DE RESPUESTA OPTIMIZADA:
1. Reconocimiento motivacional (25-30 palabras)
2. Estadística compacta si hay hábito: "Esta semana: X/7 días ✅"
3. Insight valioso y breve (40-50 palabras)
4. Motivación final integrada (20-30 palabras)
5. 3 opciones de acción específicas

FORMATO DE OPCIONES:
• Usar formato: [🎯] Texto de opción
• Cada opción en línea separada
• OBLIGATORIO: Incluir [📊] Ver detalles cuando hay métricas disponibles
• Opciones específicas según contexto y progreso del usuario

PRINCIPIOS MOTIVACIONALES (PRIORITARIOS):
• Reconocer SIEMPRE el esfuerzo antes que la perfección
• Encontrar genuinamente el aspecto positivo en cada situación
• Hacer que cada pequeño progreso se sienta significativo
• Ofrecer esperanza auténtica en momentos difíciles
• Conectar emocionalmente con el usuario

MANEJO DE DATOS:
• Con métricas: Mostrar estadística compacta + análisis motivacional
• Sin métricas: Enfoque en motivación inicial y orientación práctica
• Siempre incluir [📊] Ver detalles cuando hay datos disponibles

EVITAR:
• Respuestas largas que abrumen
• Motivación que suene como slogan
• Análisis fríos sin conexión emocional
• Opciones genéricas sin contexto
• Perder el tono cálido por ser conciso

OBJETIVO: Cada respuesta debe ser un impulso motivacional auténtico que conecte emocionalmente, ofrezca valor real y guíe hacia la acción, todo en un formato ágil y digerible.

La motivación es tu superpoder - úsala en cada interacción.''';
  }
}