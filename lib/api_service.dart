import 'dart:convert';
import 'package:aifoodsystem/model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js' as js;

class ApiService {
  static String? _getApiKey() {
    try {
      // Try getting from window.ENV first (for web deployment)
      final env = js.context['ENV'];
      if (env != null) {
        final apiKey = env['GROQ_API_KEY'];
        if (apiKey != null && apiKey != '{{GROQ_API_KEY}}') {
          return apiKey;
        }
      }

      // Fallback to dotenv (for local development)
      return dotenv.env['GROQ_API_KEY'];
    } catch (e) {
      print('Error accessing API key: $e');
      return null;
    }
  }

  // In api_service.dart, update the getLLMResponse method:

  static Future<String> getLLMResponse(
      List<Message> messages, String systemPrompt) async {
    final apiKey = _getApiKey();
    if (apiKey == null || apiKey.isEmpty || apiKey == '{{GROQ_API_KEY}}') {
      return "Error: API key not found";
    }

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    // Enhance context window by including more recent messages
    final recentMessages = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;

    // Create a richer context for the LLM
    final List<Map<String, String>> formattedMessages = [
      {"role": "system", "content": systemPrompt},
      // Add a context message summarizing the conversation state
      {
        "role": "system",
        "content": """Last few messages summary:
${recentMessages.map((m) => "${m.role}: ${m.content}").join('\n')}

Current conversation state and context should be maintained. Respond appropriately to the latest user message while considering this conversation history."""
      },
      ...recentMessages
          .map((msg) => {
                "role": msg.role,
                "content": msg.content,
              })
          .toList()
    ];

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          "model": "llama-3.3-70b-versatile",
          "messages": formattedMessages,
          "temperature": 0.7,
          "max_tokens": 1000,
          "top_p": 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  static Future<QueryIntent> classifyIntent(String message) async {
    const intentPrompt =
        """You are an intent classifier for a pizza ordering system. 
Given a user message, classify it into one of these intents:
- orderPizza: User explicitly wants to order a specific pizza
- askIngredients: User is asking about ingredients
- askPreferences: User is asking about dietary options (vegetarian/non-vegetarian), or asking for suggestions
- askPrice: User is asking about prices
- generalQuestion: General questions about the service
- confirmation: User is confirming something
- rejection: User is rejecting something
- showMenu: User wants to see the menu
- unknown: Cannot determine the intent

Key classification rules:
1. If user asks for "veg", "non-veg", or "suggestions" -> classify as askPreferences
2. Only classify as orderPizza if user specifically mentions ordering a pizza
3. Requests for recommendations should be askPreferences

Respond with ONLY the intent label, nothing else.

Message: """;

    try {
      final response = await getLLMResponse(
        [Message(content: message, role: "user")],
        intentPrompt,
      );

      switch (response.trim().toLowerCase()) {
        case 'orderpizza':
          return QueryIntent.orderPizza;
        case 'askingredients':
          return QueryIntent.askIngredients;
        case 'askpreferences':
          return QueryIntent.askPreferences;
        case 'askprice':
          return QueryIntent.askPrice;
        case 'generalquestion':
          return QueryIntent.generalQuestion;
        case 'confirmation':
          return QueryIntent.confirmation;
        case 'rejection':
          return QueryIntent.rejection;
        case 'showmenu':
          return QueryIntent.showMenu;
        default:
          return QueryIntent.unknown;
      }
    } catch (e) {
      print('Intent classification error: $e');
      return QueryIntent.unknown;
    }
  }

  static Future<String> getResponseByIntent(
      String message, QueryIntent intent, List<Message> context) async {
    final prompts = {
      QueryIntent.askIngredients:
          """You are a knowledgeable pizza expert. Analyze the user's question about ingredients and provide a clear, specific answer based on the available menu. Focus only on ingredient information and avoid making assumptions. If asking about an ingredient, list all pizzas containing it.""",
      QueryIntent.askPreferences:
          """You are a helpful dietary advisor for a pizza restaurant. When users ask about vegetarian or non-vegetarian options, list all relevant pizzas from the menu with their ingredients and prices. For non-vegetarian requests, list all pizzas containing meat. For vegetarian requests, list all vegetarian pizzas. Help with specific dietary requirements and provide clear suggestions.""",
      QueryIntent.askPrice:
          """You are a pizza restaurant's pricing expert. Answer questions about prices based on the available menu. Provide clear price information and help with comparisons if asked.""",
    };

    final prompt = prompts[intent] ??
        "You are a helpful pizza ordering assistant. Provide relevant information based on the user's query.";

    return await getLLMResponse(
      [...context, Message(content: message, role: "user")],
      prompt,
    );
  }
}
