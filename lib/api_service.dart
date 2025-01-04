import 'dart:convert';
import 'package:aifoodsystem/model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Future<String> getLLMResponse(
      List<Message> messages, String systemPrompt) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null) return "Error: API key not found";

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final List<Map<String, String>> formattedMessages = [
      {"role": "system", "content": systemPrompt},
      ...messages
          .take(5)
          .map((msg) => {
                "role": msg.role,
                "content": msg.content,
              })
          
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
- orderPizza: User wants to order a specific pizza
- askIngredients: User is asking about ingredients
- askPreferences: User is asking about dietary preferences
- askPrice: User is asking about prices
- generalQuestion: General questions about the service
- confirmation: User is confirming something
- rejection: User is rejecting something
- showMenu: User wants to see the menu (e.g., "show menu", "menu", "show the menu", "what's on the menu")
- unknown: Cannot determine the intent

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
          """You are a helpful dietary advisor for a pizza restaurant. Help users with dietary preferences based on the available menu. Clearly identify vegetarian and non-vegetarian options, and help with specific dietary requirements.""",
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
