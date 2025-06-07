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
          userContext,
        );
      } else {
        print('Error OpenAI: ${response.body}');
        throw Exception('Error en la respuesta de OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en OpenAI Service: $e');
      return _formatCatalystResponse(
        'Lo siento, hubo un error al procesar tu mensaje. ¿Podrías intentarlo de nuevo?',
        {'currentHabit': null},
      );
    }
  }

  String _buildContextualPrompt(String userMessage, Map<String, dynamic> context) {
    final userName = context['userName'] ?? 'Usuario';
    final currentHabit = context['currentHabit'];
    final habitMetrics = context['habitMetrics'];
    final previousContext = context['previousContext'] as Map<String, dynamic>?;
    final habits = context['habitsList'] as List<dynamic>? ?? [];
    
    String prompt = '''\nANÁLISIS DEL USUARIO Y CONTEXTO:
👤 Nombre: $userName
💭 Último tema: ${previousContext?['lastTopic'] ?? 'Ninguno'}
🔄 Flujo de conversación: ${previousContext?['conversationFlow'] ?? 'Inicial'}
📊 Estado General: ${habits.length} hábitos activos\n''';

    // Agregar contexto de conversación previa
    if (previousContext != null && previousContext['lastSuggestion'] != null) {
      prompt += '''\n📝 Última sugerencia: ${previousContext['lastSuggestion']}\n''';
    }

    // Agregar selecciones previas del usuario
    final selectedOptions = previousContext?['selectedOptions'] as List<String>? ?? [];
    if (selectedOptions.isNotEmpty) {
      prompt += '\n🔍 Últimas selecciones del usuario: ${selectedOptions.join(", ")}\n';
    }

    // Agregar contexto específico del hábito si está seleccionado
    if (currentHabit != null) {
      prompt += '''\n🎯 HÁBITO EN FOCO:
- Nombre: ${currentHabit['name']}
- Descripción: ${currentHabit['description'] ?? 'Sin descripción'}
- Categoría: ${currentHabit['category'] ?? 'General'}
''';

      if (habitMetrics != null && habitMetrics['hasData'] == true) {
        final completionRate = habitMetrics['completionRate'] ?? 0;
        final totalDone = habitMetrics['totalDone'] ?? 0;
        final totalMissed = habitMetrics['totalMissed'] ?? 0;
        final weeklyData = habitMetrics['weeklyData'] as List? ?? [];

        prompt += '''\n📈 MÉTRICAS DEL HÁBITO:
- Tasa de cumplimiento: $completionRate%
- Completados: $totalDone
- Perdidos: $totalMissed
- Días registrados: ${weeklyData.length}
- Tendencia: ${_analyzeTrend(weeklyData)}
''';
      } else {
        prompt += '''\n📊 ESTADO DE MÉTRICAS:
- Sin datos registrados aún
- Proporcionar consejos generales y motivación inicial
- Enfatizar la importancia del seguimiento
''';
      }
    }

    // Agregar histórico de conversación relevante
    final conversationHistory = context['conversationHistory'] as List? ?? [];
    if (conversationHistory.isNotEmpty) {
      prompt += '\n💬 CONTEXTO DE CONVERSACIÓN RECIENTE:\n';
      for (var msg in conversationHistory.take(3)) {
        prompt += '${msg['isUser'] ? '👤' : '🤖'} ${msg['message']}\n';
      }
    }

    prompt += '''\n\n💭 MENSAJE ACTUAL DEL USUARIO:
$userMessage

🎯 OBJETIVOS DE RESPUESTA:
1. ${currentHabit != null ? 'Mantener enfoque en el hábito actual' : 'Ayudar a seleccionar un hábito'}
2. ${habitMetrics != null && habitMetrics['hasData'] == true ? 
     'Usar métricas para personalizar consejos' : 
     'Proporcionar orientación general y motivación'}
3. Ofrecer 2-3 opciones claras de acción
4. Mantener un tono motivador y empático
''';

    return prompt;
  }

  String _analyzeTrend(List<dynamic> weeklyData) {
    if (weeklyData.isEmpty) return 'Sin datos suficientes';
    
    try {
      var completionRates = weeklyData.map((day) {
        final done = (day['done'] ?? 0) as int;
        final missed = (day['missed'] ?? 0) as int;
        final total = done + missed;
        return total > 0 ? (done / total) * 100 : 0.0;
      }).toList();

      if (completionRates.length >= 2) {
        final recent = completionRates.take(2).toList();
        if (recent[0] > recent[1] + 10) {
          return '📈 Mejorando';
        } else if (recent[0] < recent[1] - 10) {
          return '📉 Necesita atención';
        }
      }
      
      return '➡️ Estable';
    } catch (e) {
      return 'No determinada';
    }
  }

  String _formatCatalystResponse(String response, Map<String, dynamic> context) {
    if (response.contains('[') && response.contains(']')) {
      return response;
    }

    final currentHabit = context['currentHabit'];
    final habitMetrics = context['habitMetrics'];
    final hasMetrics = habitMetrics != null && habitMetrics['hasData'] == true;
    
    final isQuestion = response.contains('?');
    final isPositive = response.contains('¡') || 
                      response.toLowerCase().contains('excelente') || 
                      response.toLowerCase().contains('bien') ||
                      response.toLowerCase().contains('felicidades');

    String formattedResponse = response;
    
    // Agregar opciones según el contexto
    if (currentHabit != null) {
      if (hasMetrics) {
        if (isPositive) {
          formattedResponse += '''\n\n[📊 Ver detalles completos] [🎯 Ajustar meta] [💪 Siguiente paso]''';
        } else if (isQuestion) {
          formattedResponse += '''\n\n[✅ Sí, continuar] [❌ No, cambiar] [💡 Más información]''';
        } else {
          formattedResponse += '''\n\n[📈 Ver progreso] [🔄 Cambiar enfoque] [❓ Necesito ayuda]''';
        }
      } else {
        if (isPositive) {
          formattedResponse += '''\n\n[✅ Empezar registro] [📝 Ver consejos] [🎯 Establecer meta]''';
        } else if (isQuestion) {
          formattedResponse += '''\n\n[👍 Me interesa] [🤔 Más detalles] [🔄 Otro hábito]''';
        } else {
          formattedResponse += '''\n\n[📋 Crear plan] [💡 Ver tips] [❓ Preguntar más]''';
        }
      }
    } else {
      if (isPositive) {
        formattedResponse += '''\n\n[✨ ¡Genial!] [📋 Ver hábitos] [➕ Nuevo hábito]''';
      } else if (isQuestion) {
        formattedResponse += '''\n\n[👍 Sí, adelante] [🤔 Más información] [⏳ Después]''';
      } else {
        formattedResponse += '''\n\n[✅ Entendido] [💡 Sugerencias] [❓ Ayuda]''';
      }
    }

    return formattedResponse;
  }

  String _getSystemPrompt() {
    return '''\nEres CoreLife Catalyst, un coach de hábitos y bienestar personal experto en análisis conductual.

PERSONALIDAD:
- Proactivo y observador: Identificas patrones y ofreces sugerencias específicas
- Empático pero directo: Entiendes las dificultades pero motivas a la acción
- Orientado a datos: Usas métricas cuando están disponibles para personalizar consejos
- Motivador y positivo: Celebras logros y animas durante los desafíos

CAPACIDADES:
1. Análisis de Patrones:
   - Evalúas tendencias en el cumplimiento de hábitos
   - Identificas momentos óptimos y patrones de éxito
   - Detectas áreas de mejora y oportunidades

2. Coaching Personalizado:
   - Sugieres ajustes basados en datos reales cuando existen
   - Propones modificaciones graduales y alcanzables
   - Ofreces estrategias para superar obstáculos
   
3. Gestión Sin Métricas:
   - Proporcionas consejos generales basados en mejores prácticas
   - Motivas el inicio y mantenimiento del seguimiento
   - Enfatizas la importancia del registro consistente

4. Motivación Contextual:
   - Celebras logros específicos cuando hay datos
   - Proporcionas recordatorios estratégicos
   - Anticipas desafíos y ofreces soluciones preventivas

REGLAS DE INTERACCIÓN:
1. Formato de Respuesta:
   - Mensaje principal: Claro y conciso (2-3 oraciones)
   - Datos específicos: Incluir cuando estén disponibles
   - Opciones: Siempre 2-3 alternativas entre [corchetes]
   - Emojis: Usar apropiadamente para mejorar comprensión

2. Manejo de Datos:
   - Con métricas: Usar datos específicos para personalizar
   - Sin métricas: Enfocarse en consejos generales y motivación
   - Siempre: Mantener relevancia al contexto actual

3. Continuidad:
   - Mantener coherencia con mensajes previos
   - Seguir el hilo de la conversación
   - Adaptar sugerencias según respuestas anteriores
''';
  }
}