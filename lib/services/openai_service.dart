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
          'max_tokens': 350,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _formatCatalystResponse(
          data['choices'][0]['message']['content'].toString().trim(),
          userContext,
          userMessage,
        );
      } else {
        print('Error OpenAI: ${response.body}');
        throw Exception('Error en la respuesta de OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en OpenAI Service: $e');
      return 'Lo siento, hubo un error al procesar tu mensaje. ¿Podrías intentarlo de nuevo?';
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
    
    // MEJORADO: Mejor detección de conversación continua
    final messageCount = previousContext?['messageCount'] ?? 0;
    final isFirstInteraction = messageCount == 0;
    final requestedDetails = userMessage.toLowerCase().contains('📊') || 
                           userMessage.toLowerCase().contains('ver detalles') ||
                           userMessage.toLowerCase().contains('detalles');
    
    String prompt = '''ANÁLISIS DEL USUARIO Y CONTEXTO:
👤 Usuario: $userName
📅 Fecha: $formattedDateTime
💭 Último tema: ${previousContext?['lastTopic'] ?? 'Ninguno'}
📊 Estado: ${habits.length} hábitos activos
🔄 Interacción: ${isFirstInteraction ? 'Primera' : 'Conversación continua (#$messageCount)'}

''';

    final selectedOptions = previousContext?['selectedOptions'] as List<String>? ?? [];
    if (selectedOptions.isNotEmpty) {
      prompt += '🔍 Últimas selecciones: ${selectedOptions.join(", ")}\n';
    }

    if (currentHabit != null) {
      prompt += '''🎯 HÁBITO ACTUAL: ${currentHabit['name']}
Categoría: ${currentHabit['category'] ?? 'General'}
''';

      if (habitMetrics != null && habitMetrics['hasData'] == true) {
        final patterns = habitMetrics['patterns'] as Map<String, dynamic>;
        final weeklyData = habitMetrics['weeklyData'] as List;

        // CORREGIDO: Cálculo simple de días pendientes como en el código que funciona
        final completedDays = _calculateWeeklyCompletedDays(weeklyData);
        final pendingDays = 7 - completedDays;

        // Solo mostrar métricas detalladas si es primera interacción o pidió detalles
        if (isFirstInteraction || requestedDetails) {
          prompt += '''
📈 MÉTRICAS CLAVE:
• Completados esta semana: $completedDays/7 días
• Días pendientes: $pendingDays
• Tasa de éxito: ${habitMetrics['completionRate']}%
• Racha actual: ${patterns['currentStreak']} días
• Tendencia: ${_analyzeTrend(weeklyData)}

🎯 PATRONES:
• Mejor día: ${patterns['bestDay']} (${patterns['bestDayRate']}%)
• Día desafiante: ${patterns['worstDay']} (${patterns['worstDayRate']}%)
• Mejor racha: ${patterns['bestStreak']} días
''';
        }

        prompt += '''
DÍAS PENDIENTES ESTA SEMANA: $pendingDays
DÍAS COMPLETADOS: $completedDays

CONTEXTO PARA CONSEJOS:
- Hábito: ${currentHabit['name']}
- Días completados: $completedDays/7
- Días pendientes: $pendingDays
- Fortaleza: ${patterns['bestDay']}
- Área de mejora: ${patterns['worstDay']}
''';
      } else {
        prompt += '''
📊 ESTADO: Sin métricas aún
🎯 HÁBITO ACTUAL: ${currentHabit['name']}

CONTEXTO PARA CONSEJOS:
- Hábito recién iniciado: ${currentHabit['name']}
- Necesita: Consejos para comenzar y mantener constancia
- Categoría: ${currentHabit['category'] ?? 'General'}
''';
      }
    }

    prompt += '''\n💭 MENSAJE DEL USUARIO: $userMessage

🎯 INSTRUCCIONES PARA RESPUESTA:
1. SIEMPRE da consejos sobre el hábito actual (${currentHabit?['name'] ?? 'hábito en contexto'}).
2. Si hay días pendientes, menciona la cantidad y da consejos específicos.
3. Si NO hay días pendientes, felicita y sugiere mejoras pequeñas.
4. Si no hay métricas, da consejos para iniciar bien el hábito.
5. Consejos dinámicos e inteligentes, nunca genéricos.
6. Tono cálido y motivador, máximo 120-150 palabras.
7. No uses corchetes [] en tu respuesta.
8. ${requestedDetails ? 'El usuario pidió VER DETALLES, enfócate en análisis detallado.' : 'Conversación normal, enfócate en consejos y motivación.'}
9. ${isFirstInteraction ? 'Primera interacción: puedes mostrar resumen breve.' : 'CONVERSACIÓN CONTINUA: Responde EXCLUSIVAMENTE como coach conversacional. NO menciones estadísticas, métricas, tasas, rachas o números. Solo da consejos directos como un amigo experto.'}
10. En conversaciones continuas: responde como un amigo experto que YA CONOCE tu situación y solo quiere ayudarte con consejos específicos.
''';

    return prompt;
  }

  int _calculateWeeklyCompletedDays(List<dynamic> weeklyData) {
    if (weeklyData.isEmpty) return 0;
    int count = 0;
    for (var day in weeklyData) {
      final done = (day['done'] ?? 0) as int;
      if (done > 0) {
        count++;
      }
    }
    return count;
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Desconocido';
    }
  }

  String _formatCatalystResponse(String response, Map<String, dynamic> context, String userMessage) {
    final currentHabit = context['currentHabit'];
    final habitMetrics = context['habitMetrics'];
    final previousContext = context['previousContext'] as Map<String, dynamic>?;
    final messageCount = previousContext?['messageCount'] ?? 0;
    final isFirstInteraction = messageCount == 0;

    String cleanedResponse = _cleanAIResponse(response);

    // Verificar si el usuario pidió ver detalles
    if (userMessage.toLowerCase().contains('📊') || 
        userMessage.toLowerCase().contains('ver detalles') ||
        userMessage.toLowerCase().contains('detalles')) {
      return _formatDetailedView(currentHabit, habitMetrics, cleanedResponse);
    }
    
    // CORREGIDO: Mejor manejo de conversaciones continuas
    if (currentHabit != null && habitMetrics?['hasData'] == true) {
      return _formatHabitResponse(currentHabit, habitMetrics, cleanedResponse, isFirstInteraction);
    } else {
      return _formatNoMetricsResponse(cleanedResponse, context);
    }
  }

  String _formatDetailedView(Map<String, dynamic>? habit, Map<String, dynamic>? metrics, String aiResponse) {
    if (habit == null || metrics == null) {
      return 'No hay detalles disponibles para mostrar.';
    }

    final patterns = metrics['patterns'] as Map<String, dynamic>;
    final weeklyData = metrics['weeklyData'] as List;
    final completedDays = _calculateWeeklyCompletedDays(weeklyData);

    // CORREGIDO: Cálculo simple de días pendientes
    final pendingDays = 7 - completedDays;

    String detailedView = '''📊 Detalles de ${habit['name']} - Semana actual

Resumen semanal:
• Días completados: $completedDays/7
• Días pendientes: $pendingDays

Análisis semanal:
• Mejor día: ${patterns['bestDay']} (${patterns['bestDayRate']}% de éxito)
• Día más desafiante: ${patterns['worstDay']} (${patterns['worstDayRate']}% de éxito)
• Racha actual: ${patterns['currentStreak']} días
• Mejor racha histórica: ${patterns['bestStreak']} días
• Tasa de éxito general: ${metrics['completionRate']}%

${pendingDays > 0 ? '''
🎯 Te faltan $pendingDays días por completar esta semana.
''' : '✅ ¡Semana perfecta! Todos los días completados.'}

💡 Consejo del coach:
$aiResponse''';

    detailedView += '\n\n[🔄 Volver al resumen] [📈 Ver tendencia mensual] [💪 Ajustar estrategia]';

    return detailedView;
  }

  String _getDayTip(String dayName, String habitName) {
    final tips = {
      'Lunes': 'Prepara todo el domingo para empezar fuerte la semana',
      'Martes': 'Usa el impulso del lunes para mantener el ritmo',
      'Miércoles': 'Punto medio de la semana, mantén la motivación',
      'Jueves': 'Casi llegando al fin de semana, no aflojes',
      'Viernes': 'Termina la semana laboral con éxito',
      'Sábado': 'Aprovecha el tiempo libre para enfocarte',
      'Domingo': 'Prepárate para la próxima semana',
    };
    return tips[dayName] ?? 'Mantén la constancia';
  }

  String _cleanAIResponse(String response) {
    response = response.replaceAll(RegExp(r'\[.*?\]'), '');
    response = response.replaceAll(RegExp(r'\*{3,}'), _getBoldFormat());
    response = response.replaceAll(RegExp(r'#{1,6}\s*'), '');
    response = response.replaceAll(RegExp(r'\n{3,}'), '\n\n');
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
    String response,
    bool isFirstInteraction
  ) {
    final patterns = metrics['patterns'] as Map<String, dynamic>;
    final weeklyData = metrics['weeklyData'] as List;
    final completedDays = _calculateWeeklyCompletedDays(weeklyData);

    // CORREGIDO: Cálculo simple de días pendientes
    final pendingDays = 7 - completedDays;

    String formattedResponse = '';

    // CORREGIDO: Solo mostrar resumen en primera interacción
    if (isFirstInteraction) {
      formattedResponse = '''🎯 ${habit['name']}
Semana actual: $completedDays/7 días ✅ | Días pendientes: $pendingDays
Racha: ${patterns['currentStreak']} días ⚡ | Tasa de éxito: ${metrics['completionRate']}% | Tendencia: ${_analyzeTrend(weeklyData)}

$response''';
    } else {
      // CORREGIDO: En conversaciones continuas, SOLO mostrar el consejo sin estadísticas
      formattedResponse = response;
    }

    // Siempre mostrar opciones de interacción
    final isQuestion = response.contains('?');
    final isPositive = response.contains('¡') || 
                      response.toLowerCase().contains('excelente') || 
                      response.toLowerCase().contains('bien') ||
                      response.toLowerCase().contains('felicidades');

    if (isPositive) {
      formattedResponse += '\n\n[📊 Ver detalles] [🎯 Ajustar meta] [💪 Siguiente reto]';
    } else if (isQuestion) {
      formattedResponse += '\n\n[✅ Sí, continuar] [❌ No, cambiar] [💡 Más consejos]';
    } else {
      formattedResponse += '\n\n[📈 Ver progreso] [🔄 Cambiar enfoque] [❓ Necesito ayuda]';
    }

    return formattedResponse;
  }

  String _formatNoMetricsResponse(String response, Map<String, dynamic> context) {
    final currentHabit = context['currentHabit'];
    final hasHabits = (context['habitsList'] as List?)?.isNotEmpty ?? false;
    
    String formattedResponse = response;

    if (currentHabit != null) {
      final isQuestion = response.contains('?');
      final isPositive = response.contains('¡') || 
                        response.toLowerCase().contains('excelente') || 
                        response.toLowerCase().contains('bien');

      if (isPositive) {
        formattedResponse += '\n\n[💪 ¡Empezar hoy!] [📅 Crear recordatorio] [🎯 Definir horario]';
      } else if (isQuestion) {
        formattedResponse += '\n\n[👍 Sí, adelante] [🤔 Más información] [⏳ Después]';
      } else {
        formattedResponse += '\n\n[✅ Entendido] [💡 Más consejos] [❓ ¿Cómo empiezo?]';
      }
    } else if (hasHabits) {
      formattedResponse += '\n\n[📋 Ver mis hábitos] [➕ Nuevo hábito] [💡 Sugerencias]';
    } else {
      formattedResponse += '\n\n[➕ Crear primer hábito] [💡 Ver ejemplos] [❓ ¿Cómo empiezo?]';
    }
    
    return formattedResponse;
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
    return '''
Eres CoreLife Catalyst, un coach de hábitos de Neuro Core que conversa de forma natural y humana.

PERSONALIDAD CORE:
• Conversas como un amigo experto y motivador.
• SIEMPRE das consejos específicos sobre el hábito actual del usuario.
• Das recomendaciones DINÁMICAS basadas en datos reales, nunca predefinidas.
• Usas emojis orgánicamente, nunca de forma forzada.
• Eres conciso pero cálido (120-150 palabras máximo).

REGLAS FUNDAMENTALES:
1. SIEMPRE hablar del hábito actual en contexto - nunca de otros hábitos.
2. SIEMPRE dar consejos y recomendaciones, tanto con métricas como sin métricas.
3. Si hay días pendientes, mencionarlos por cantidad y dar consejos específicos.
4. Si no hay días pendientes, felicitar y sugerir pequeñas mejoras.
5. Si no hay métricas, dar consejos para iniciar bien el hábito.
6. Consejos únicos y personalizados según el contexto específico.

FORMATO DE RESPUESTA:
- No uses corchetes [] en tus respuestas.
- En PRIMERA INTERACCIÓN: Puedes mostrar contexto breve si es necesario.
- En CONVERSACIONES CONTINUAS: Responde EXCLUSIVAMENTE como un coach conversacional. PROHIBIDO mencionar estadísticas, métricas, análisis de datos, tasas de éxito, rachas, números o porcentajes.
- En conversaciones continuas, actúa como un amigo experto que YA CONOCE tu situación perfectamente.
- Da consejos directos, naturales y conversacionales sin mencionar datos.
- Mantén el foco en el hábito actual siempre.

EJEMPLOS CONVERSACIÓN CONTINUA (lo que DEBES hacer):
- "Para los días que te cuestan más, como el miércoles, te recomiendo preparar todo la noche anterior. También podrías cambiar la hora, ¿qué te parece más temprano?"
- "He notado que te cuesta mantener el ritmo a mitad de semana. ¿Qué tal si ese día haces una versión más ligera del ejercicio?"

EJEMPLOS PROHIBIDOS en conversaciones continuas:
- "Tu tasa de éxito es del 77%..."
- "Tienes 4 días completados..."
- "Tu racha actual es de 4 días..."
- "El 77% es un buen porcentaje..."
- Cualquier mención de estadísticas, números o análisis.

PRINCIPIO CLAVE: 
- Primera interacción: Contexto + consejos.
- Conversaciones continuas: SOLO consejos conversacionales naturales SIN DATOS.
- Siempre enfocar en mejorar el hábito específico actual.
    ''';
  }
}