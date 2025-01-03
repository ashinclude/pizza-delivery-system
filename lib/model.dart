
enum QueryIntent {
  orderPizza,
  askIngredients,
  askPreferences,
  askPrice,
  generalQuestion,
  confirmation,
  rejection,
  showMenu,  // Add this new intent
  unknown
}
enum OrderStatus {
  initiated,
  confirmed,
  cooking,
  cooked,
  outForDelivery,
  delivered,
  reviewRequested
}

class Message {
  final String content;
  final String role;
  final DateTime timestamp;
  final String? agentType;
  final Map<String, dynamic>? metadata;

  Message({
    required this.content,
    required this.role,
    this.agentType,
    this.metadata,
  }) : timestamp = DateTime.now();
}

class WalletState {
  double balance;
  WalletState({this.balance = 2000.0});  // Default balance
}

class MenuItem {
  final String name;
  final double price;
  final List<String> ingredients;
  final String? diet;

  MenuItem({
    required this.name,
    required this.price,
    required this.ingredients,
    this.diet,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'],
      price: json['price'].toDouble(),
      ingredients: List<String>.from(json['ingredients']),
      diet: json['diet'],
    );
  }
}



