// lib/screens/pizza_delivery_screen.dart
import 'dart:math';

import 'package:aifoodsystem/api_service.dart';
import 'package:aifoodsystem/chat_widget.dart';
import 'package:aifoodsystem/constants.dart';
import 'package:aifoodsystem/model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PizzaDeliveryScreen extends StatefulWidget {
  const PizzaDeliveryScreen({super.key});
  @override
  _PizzaDeliveryScreenState createState() => _PizzaDeliveryScreenState();
}

class _PizzaDeliveryScreenState extends State<PizzaDeliveryScreen> {
  static const Color userAgentColor = Color(0xFF2196F3);
  static const Color kitchenAgentColor = Color(0xFF4CAF50);
  static const Color deliveryAgentColor = Color(0xFFF57C00);
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  OrderStatus _currentStatus = OrderStatus.initiated;
  final Map<String, String> _agentOutputs = {};
  bool _isProcessing = false;
  bool _isWaitingForFeedback = false;
  String? _currentOrderDetails;
  double _walletBalance = INITIAL_WALLET_BALANCE;

  bool _isWaitingForOrderOption = false;

  String? _lastOrderedItem;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final menuText = MENU
        .map((item) =>
            "- ${item.name}: ₹${item.price} (${item.ingredients.join(', ')})")
        .join("\n");
    _addMessage(
        content:
            "Welcome to our Pizza Delivery System! Here's our menu:\n\n$menuText\n\nWhat would you like to order?",
        role: "assistant",
        agentType: "user_agent");
  }

  void _addMessage({
    required String content,
    required String role,
    String? agentType,
    Map<String, dynamic>? metadata,
  }) {
    setState(() {
      _messages.add(Message(
        content: content,
        role: role,
        agentType: agentType,
        metadata: metadata,
      ));
    });
    _scrollToBottom();
  }

// Update the _handleUserAgent method in _PizzaDeliveryScreenState
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0;
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    int matches = 0;
    int maxLength = s1.length > s2.length ? s1.length : s2.length;

    for (int i = 0; i < s1.length && i < s2.length; i++) {
      if (s1[i] == s2[i]) matches++;
    }

    return matches / maxLength;
  }

  PizzaMatch? _findMatchingPizza(String userInput) {
    userInput = userInput.toLowerCase();
    List<PizzaMatch> possibleMatches = [];

    // Helper function for word similarity
    double getWordSimilarity(String word1, String word2) {
      word1 = word1.toLowerCase();
      word2 = word2.toLowerCase();

      // Direct match
      if (word1 == word2) return 1.0;

      // Common variations
      Map<String, List<String>> variations = {
        'burst': ['brust', 'bust', 'bhurst'],
        'cheese': ['chese', 'cheez', 'chees'],
        'tandoori': ['tanduri', 'tandoor', 'tandori'],
        'extravaganza': ['extravagence', 'extravagent', 'extravaganza'],
        'margherita': ['margarita', 'marghereta', 'margheritta'],
        'paneer': ['panir', 'paner', 'pneer'],
      };

      // Check variations
      for (var base in variations.keys) {
        if ((base == word1 && variations[base]!.contains(word2)) ||
            (base == word2 && variations[base]!.contains(word1))) {
          return 0.9;
        }
      }

      // Levenshtein distance for other cases
      int distance = _levenshteinDistance(word1, word2);
      int maxLength = max(word1.length, word2.length);
      return 1 - (distance / maxLength);
    }

    // Process each menu item
    for (var item in MENU) {
      double maxConfidence = 0.0;

      // Extract key terms from pizza name
      List<String> pizzaTerms =
          item.name.toLowerCase().replaceAll(' pizza', '').split(' ');

      // Extract key terms from user input
      List<String> userTerms = userInput
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .split(' ')
          .where((term) => term.length > 2) // Filter out very short words
          .toList();

      // Match each user term against pizza terms
      for (var userTerm in userTerms) {
        for (var pizzaTerm in pizzaTerms) {
          double similarity = getWordSimilarity(userTerm, pizzaTerm);
          maxConfidence = max(maxConfidence, similarity);
        }
      }

      // Consider previous context
      if (_messages.length >= 2) {
        String prevResponse =
            _messages[_messages.length - 2].content.toLowerCase();
        if (prevResponse.contains(item.name.toLowerCase())) {
          maxConfidence +=
              0.1; // Boost confidence if this pizza was just mentioned
        }
      }

      if (maxConfidence > 0.6) {
        // Threshold for considering it a match
        possibleMatches.add(PizzaMatch(item, maxConfidence));
      }
    }

    // Sort by confidence and return the best match
    if (possibleMatches.isNotEmpty) {
      possibleMatches.sort((a, b) => b.confidence.compareTo(a.confidence));
      return possibleMatches.first;
    }

    return null;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i <= s2.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

// Replace the existing _handleUserAgent method with this one
Future<void> _handleUserAgent() async {
    final userMessage = _messages.last.content;
    
    try {
      // Skip intent classification if we're in the middle of an order confirmation
      if (_currentOrderDetails != null &&
          _currentStatus == OrderStatus.initiated) {
        final confirmationKeywords = [
          'yes',
          'confirm',
          'sure',
          'okay',
          'ok',
          'proceed',
          'go ahead',
          'yep',
          'yeah'
        ];
        final rejectionKeywords = [
          'no',
          'cancel',
          'reject',
          "don't",
          'stop',
          'nope'
        ];

        if (confirmationKeywords
            .any((word) => userMessage.toLowerCase().contains(word))) {
          // Handle confirmation as before...
          final selectedItem = MENU.firstWhere(
            (item) => item.name == _currentOrderDetails,
            orElse: () => MenuItem(name: '', price: 0, ingredients: []),
          );

          _deductFromWallet(selectedItem.price);
          setState(() => _currentStatus = OrderStatus.confirmed);

          _addMessage(
            content: WALLET_CONFIRMATION_MESSAGE
                .replaceAll("{PRICE}", selectedItem.price.toString())
                .replaceAll("{BALANCE}", _walletBalance.toStringAsFixed(2)),
            role: "assistant",
            agentType: "user_agent",
          );

          await _processOrder();
          return;
        } else if (rejectionKeywords
            .any((word) => userMessage.toLowerCase().contains(word))) {
          // Handle rejection as before...
          _addMessage(
            content:
                "No problem! Your wallet won't be charged. Would you like to order something else?",
            role: "assistant",
            agentType: "user_agent",
          );
          _resetOrderState();
          return;
        }
      }

      // Pre-process message for common queries
      final lowerMessage = userMessage.toLowerCase();
      if (lowerMessage.contains('non veg') || lowerMessage.contains('non-veg')) {
        final nonVegPizzas = MENU.where((item) => item.diet == "non-vegetarian").toList();
        _addMessage(
          content: """Here are our non-vegetarian pizzas:
${nonVegPizzas.map((pizza) => "- ${pizza.name}: ₹${pizza.price}\n  Contains: ${pizza.ingredients.join(', ')}").join('\n')}

Would you like to order any of these pizzas?""",
          role: "assistant",
          agentType: "user_agent",
        );
        return;
      }

      // Check for specific pizza inquiries
      final specificPizza = _findMatchingPizza(userMessage);
      if (specificPizza != null) {
        _addMessage(
          content: """${specificPizza.item.name}:
Price: ₹${specificPizza.item.price}
Ingredients: ${specificPizza.item.ingredients.join(', ')}

Would you like to order this pizza?""",
          role: "assistant",
          agentType: "user_agent",
        );
        return;
      }

      // Classify the intent
      final intent = await ApiService.classifyIntent(userMessage);

      switch (intent) {
        case QueryIntent.orderPizza:
          // Try to find a matching pizza using our enhanced matching
          final pizzaMatch = _findMatchingPizza(userMessage);

          if (pizzaMatch != null) {
            _currentOrderDetails = pizzaMatch.item.name;

            // Check wallet balance
            if (pizzaMatch.item.price > _walletBalance) {
              _addMessage(
                content: INSUFFICIENT_BALANCE_MESSAGE
                    .replaceAll("{ITEM}", pizzaMatch.item.name)
                    .replaceAll("{BALANCE}", _walletBalance.toStringAsFixed(2)),
                role: "assistant",
                agentType: "user_agent",
              );
              return;
            }

            // If confidence is very high, proceed with order
            if (pizzaMatch.confidence > 0.9) {
              _addMessage(
                content: WALLET_CHARGE_MESSAGE
                    .replaceAll("{ITEM}", pizzaMatch.item.name)
                    .replaceAll("{PRICE}", pizzaMatch.item.price.toString()),
                role: "assistant",
                agentType: "user_agent",
              );
            } else {
              // If confidence is lower, ask for confirmation
              _addMessage(
                content:
                    "Did you mean ${pizzaMatch.item.name}? This pizza contains: ${pizzaMatch.item.ingredients.join(', ')}. Would you like to order this?",
                role: "assistant",
                agentType: "user_agent",
              );
            }
          } else {
            final response = await ApiService.getResponseByIntent(
                userMessage, intent, _messages);
            _addMessage(
                content: response, role: "assistant", agentType: "user_agent");
          }
          break;

        case QueryIntent.askIngredients:
        case QueryIntent.askPreferences:
        case QueryIntent.askPrice:
        case QueryIntent.generalQuestion:
          final response = await ApiService.getResponseByIntent(
              userMessage, intent, _messages);
          _addMessage(
              content: response, role: "assistant", agentType: "user_agent");
          break;

        case QueryIntent.confirmation:
        case QueryIntent.rejection:
          final response = await ApiService.getResponseByIntent(
              userMessage, intent, _messages);
          _addMessage(
              content: response, role: "assistant", agentType: "user_agent");
          break;

        case QueryIntent.showMenu:
          _showMenu();
          break;

        case QueryIntent.unknown:
        default:
          final response = await ApiService.getLLMResponse(_messages, USER_AGENT_PROMPT);
          _addMessage(
              content: response, role: "assistant", agentType: "user_agent");
          break;
      }
    } catch (e) {
      // If error occurs, try to give a contextual response based on the user's message
      final lowerMessage = userMessage.toLowerCase();
      if (lowerMessage.contains('non veg') || lowerMessage.contains('non-veg')) {
        final nonVegPizzas = MENU.where((item) => item.diet == "non-vegetarian").toList();
        _addMessage(
          content: """Here are our non-vegetarian pizzas:
${nonVegPizzas.map((pizza) => "- ${pizza.name}: ₹${pizza.price}\n  Contains: ${pizza.ingredients.join(', ')}").join('\n')}

Would you like to order any of these pizzas?""",
          role: "assistant",
          agentType: "user_agent",
        );
      } else {
        // If we can't determine the context, provide a helpful response
        _addMessage(
          content: "I can help you with our menu, specific pizzas, or placing an order. What would you like to know about?",
          role: "assistant",
          agentType: "user_agent",
        );
      }
    }
  }

  Future<void> _processOrder() async {
    setState(() => _isProcessing = true);

    _lastOrderedItem = _currentOrderDetails;

    try {
      // Kitchen Agent - Start cooking
      setState(() => _currentStatus = OrderStatus.cooking);
      final cookingStartTime = DateTime.now();

      // Initial kitchen update
      _addMessage(
        content:
            "Agent 2: Order received at ${cookingStartTime.toString().split('.')[0]}",
        role: "assistant",
        agentType: "kitchen_agent",
      );
      await Future.delayed(const Duration(seconds: 5));
      _addMessage(
        content: "Your order is being prepared. Halfway there!",
        role: "assistant",
        agentType: "kitchen_agent",
      );
      await Future.delayed(const Duration(seconds: 5));
      final cookingEndTime = DateTime.now();
      _addMessage(
        content:
            "Agent 2: Order prepared at ${cookingEndTime.toString().split('.')[0]}",
        role: "assistant",
        agentType: "kitchen_agent",
      );
      setState(() => _currentStatus = OrderStatus.cooked);
      // Delivery Agent - Start delivery
      setState(() => _currentStatus = OrderStatus.outForDelivery);
      final deliveryStartTime = DateTime.now();
      _addMessage(
        content:
            "Agent 3: Starting delivery at ${deliveryStartTime.toString().split('.')[0]}",
        role: "assistant",
        agentType: "delivery_agent",
      );
      await Future.delayed(const Duration(seconds: 5));
      _addMessage(
        content: "Your order is on the way! Driver is getting closer.",
        role: "assistant",
        agentType: "delivery_agent",
      );
      await Future.delayed(const Duration(seconds: 5));
      final deliveryEndTime = DateTime.now();
      _addMessage(
        content:
            "Agent 3: Order delivered at ${deliveryEndTime.toString().split('.')[0]}",
        role: "assistant",
        agentType: "delivery_agent",
      );
      setState(() => _currentStatus = OrderStatus.delivered);
      // Delay feedback request by 20 seconds
      await Future.delayed(const Duration(seconds: 20));
      await _askForReview();
    } catch (e) {
      _addMessage(
        content:
            "I apologize, but there was an error processing your order. Please try again.",
        role: "assistant",
        agentType: "user_agent",
      );
      _resetOrderState();
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _askForReview() async {
    setState(() => _isWaitingForFeedback = true);
    _addMessage(
      content: """Thank you for ordering with us! Your order has been delivered.
Would you like to provide feedback about your experience?
(Type 'yes' if you'd like to leave feedback, or 'no' to skip)""",
      role: "assistant",
      agentType: "user_agent",
    );
  }

  void _handleFeedback(String userResponse) {
    if (_isWaitingForFeedback) {
      if (userResponse.toLowerCase().contains('yes')) {
        _addMessage(
          content: """Great! Please tell me about:
- Food quality
- Delivery experience
- Overall service
- Any suggestions for improvement""",
          role: "assistant",
          agentType: "user_agent",
        );
        setState(() {
          _isWaitingForFeedback = false;
          _isWaitingForOrderOption = false;
        });
      } else if (userResponse.toLowerCase().contains('no')) {
        setState(() {
          _isWaitingForFeedback = false;
          _isWaitingForOrderOption = true;
        });
        _showOrderOptions();
      }
    } else if (_isWaitingForOrderOption) {
      _handleOrderOption(userResponse);
    } else {
      setState(() {
        _isWaitingForOrderOption = true;
      });
      _showOrderOptions();
    }
  }

  Future<void> _handleOrderOption(String response) async {
    if (response == '1' || response.toLowerCase().contains('new')) {
      setState(() {
        _isWaitingForOrderOption = false;
        _currentStatus = OrderStatus.initiated;
      });
      _showMenu();
    } else if (response == '2' || response.toLowerCase().contains('reorder')) {
      if (_lastOrderedItem != null) {
        setState(() {
          _isWaitingForOrderOption = false;
          _currentStatus = OrderStatus.initiated;
          _currentOrderDetails = _lastOrderedItem;
        });

        final selectedItem = MENU.firstWhere(
          (item) => item.name == _lastOrderedItem,
          orElse: () => MenuItem(name: '', price: 0, ingredients: []),
        );

        if (selectedItem.price > _walletBalance) {
          _addMessage(
            content: INSUFFICIENT_BALANCE_MESSAGE
                .replaceAll("{ITEM}", selectedItem.name)
                .replaceAll("{BALANCE}", _walletBalance.toStringAsFixed(2)),
            role: "assistant",
            agentType: "user_agent",
          );
          return;
        }

        _addMessage(
          content: WALLET_CHARGE_MESSAGE
              .replaceAll("{ITEM}", selectedItem.name)
              .replaceAll("{PRICE}", selectedItem.price.toString()),
          role: "assistant",
          agentType: "user_agent",
        );
      } else {
        setState(() {
          _isWaitingForOrderOption = false;
          _currentStatus = OrderStatus.initiated;
        });
        _addMessage(
          content: "I couldn't find your last order. Let me show you our menu.",
          role: "assistant",
          agentType: "user_agent",
        );
        _showMenu();
      }
    } else {
      _addMessage(
        content:
            "Please select either 1 for a new order or 2 to reorder your last item.",
        role: "assistant",
        agentType: "user_agent",
      );
    }
  }

  void _showOrderOptions() {
    String message = """Thank you! Would you like to:
1. Place a new order
2. Reorder ${_lastOrderedItem ?? 'your last item'}

Please select 1 or 2.""";

    _addMessage(
      content: message,
      role: "assistant",
      agentType: "user_agent",
    );
  }

  void _showMenu() {
    _addMessage(
      content: """Here's our menu:
${MENU.map((item) => "${item.name}: ₹ ${item.price} \n- ${item.ingredients.join(', ')}").join('\n\n')}

Which pizza would you like to order?""",
      role: "assistant",
      agentType: "user_agent",
    );
  }

  void _resetOrderState() {
    setState(() {
      _currentStatus = OrderStatus.initiated;
      _currentOrderDetails = null;
      _isWaitingForFeedback = false;
      _isWaitingForOrderOption = false;
      _isProcessing = false;
      _agentOutputs.clear();
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty) return;
    _messageController.clear();
    _addMessage(content: text, role: "user");
    setState(() => _isProcessing = true);

    try {
      if (_isWaitingForFeedback) {
        _handleFeedback(text);
      } else if (_isWaitingForOrderOption) {
        await _handleOrderOption(text);
      } else if (_currentStatus == OrderStatus.initiated) {
        await _handleUserAgent();
      } else {
        _handleFeedback(text);
      }
    } catch (e) {
      _addMessage(
        content:
            "I apologize, but I couldn't process that request. Please try again.",
        role: "assistant",
        agentType: "user_agent",
      );
    }

    setState(() => _isProcessing = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatusDialog(
        currentStatus: _currentStatus,
        agentOutputs: _agentOutputs,
      ),
    );
  }

  void _deductFromWallet(double amount) {
    setState(() {
      _walletBalance -= amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode focusNode = FocusNode();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1,
        title: Text(
          'AI Pizza Manager Agent',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          WalletBalance(
            balance: _walletBalance,
            backgroundColor: Colors.black,
            textColor: Colors.white,
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ModernMessageBubble(
                    key: ValueKey('message_$index'),
                    message: message,
                    userAgentColor: userAgentColor,
                    kitchenAgentColor: kitchenAgentColor,
                    deliveryAgentColor: deliveryAgentColor,
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: focusNode,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: (text) {
                          _handleSubmitted(text);
                          focusNode.requestFocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          if (_messageController.text.isNotEmpty) {
                            _handleSubmitted(_messageController.text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PizzaMatch {
  final MenuItem item;
  final double confidence;

  PizzaMatch(this.item, this.confidence);
}
