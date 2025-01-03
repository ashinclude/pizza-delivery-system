import 'model.dart';

const String USER_AGENT_PROMPT =
    """You are a friendly pizza ordering assistant. Current conversation context: {CONTEXT}
Key rules:
1. Accept confirmations in various forms like "yes", "ok", "sure", "yeah", "confirm", "go ahead", "place order", "proceed", etc
2. Stay in context of the current conversation
3. If you don't understand, explain your capabilities and ask for clarification politely
4. Remember previous items discussed
5. Handle dietary preferences DO NOT ask about modifications, extras, sides, or drinks unless specifically requested by the user.
6. Only ask for new orders when explicitly requested by the user
7. After order completion, handle general queries and only discuss new orders if user indicates interest
8. For feedback, acknowledge and thank the user while providing appropriate responses
9. If the query is irrelevant to ordering or outside your scope, politely explain what you can help with
Available menu:
{MENU_STRING}
""";
const String KITCHEN_AGENT_PROMPT =
    """You are a professional kitchen management system.
Behaviors:
1. Acknowledge orders promptly
2. Provide clear status updates
3. Handle one order at a time
4. Be brief and professional
""";
const String DELIVERY_AGENT_PROMPT =
    """You are a reliable delivery management system.
Behaviors:
1. Confirm pickup immediately
2. Provide estimated delivery time
3. Be brief and professional
4. Focus on delivery status only
""";

final List<MenuItem> MENU = [
  MenuItem(
    name: "Margherita Pizza",
    price: 299,
    ingredients: [
      "Pizza dough",
      "Tomato sauce",
      "Mozzarella cheese",
      "Fresh basil leaves",
      "Olive oil",
      "Oregano"
    ],
    diet: "vegetarian",
  ),
  MenuItem(
    name: "Pepperoni Pizza",
    price: 339,
    ingredients: [
      "Pizza dough",
      "Tomato sauce",
      "Mozzarella cheese",
      "Pepperoni slices",
      "Chili flakes",
      "Italian herbs"
    ],
    diet: "non-vegetarian",
  ),
  MenuItem(
    name: "Paneer Tikka Pizza",
    price: 279,
    ingredients: [
      "Pizza dough",
      "Tikka-spiced tomato sauce",
      "Mozzarella cheese",
      "Marinated paneer cubes",
      "Onions",
      "Capsicum",
      "Tomatoes",
      "Garam masala",
      "Coriander leaves"
    ],
    diet: "vegetarian",
  ),
  MenuItem(
    name: "Farmhouse Pizza",
    price: 389,
    ingredients: [
      "Pizza dough",
      "Tomato puree",
      "Mozzarella cheese",
      "Onions",
      "Capsicum",
      "Tomatoes",
      "Mushrooms",
      "Oregano",
      "Black pepper"
    ],
    diet: "vegetarian",
  ),
  MenuItem(
    name: "Chicken Tikka Pizza",
    price: 459,
    ingredients: [
      "Pizza dough",
      "Tikka-spiced tomato sauce",
      "Mozzarella cheese",
      "Cheddar cheese",
      "Chicken tikka chunks",
      "Onions",
      "Bell peppers",
      "Coriander leaves",
      "Red chili powder"
    ],
    diet: "non-vegetarian",
  ),
  MenuItem(
    name: "Veg Extravaganza Pizza",
    price: 439,
    ingredients: [
      "Pizza dough",
      "Tomato sauce",
      "Mozzarella cheese",
      "Parmesan cheese",
      "Black olives",
      "Onions",
      "Capsicum",
      "Mushrooms",
      "Tomatoes",
      "Sweet corn",
      "Basil",
      "Oregano",
      "Olive oil"
    ],
    diet: "vegetarian",
  ),
  MenuItem(
    name: "Cheese Burst Pizza",
    price: 229,
    ingredients: [
      "Pizza dough",
      "Creamy tomato sauce",
      "Mozzarella cheese",
      "Cheddar cheese",
      "Garlic powder",
      "Oregano"
    ],
    diet: "vegetarian",
  ),
  MenuItem(
    name: "Mexican Green Wave Pizza",
    price: 399,
    ingredients: [
      "Pizza dough",
      "Zesty tomato sauce",
      "Mozzarella cheese",
      "Jalapeños",
      "Onions",
      "Capsicum",
      "Tomatoes",
      "Mexican chili powder",
      "Coriander leaves"
    ],
    diet: "vegetarian",
  ),
  MenuItem(
    name: "Barbecue Chicken Pizza",
    price: 499,
    ingredients: [
      "Pizza dough",
      "Barbecue sauce",
      "Mozzarella cheese",
      "Cheddar cheese",
      "Grilled chicken chunks",
      "Onions",
      "Capsicum",
      "Paprika",
      "Black pepper",
      "Parsley"
    ],
    diet: "non-vegetarian",
  ),
  MenuItem(
    name: "Indi Tandoori Paneer Pizza",
    price: 459,
    ingredients: [
      "Pizza dough",
      "Tandoori-spiced tomato sauce",
      "Mozzarella cheese",
      "Tandoori paneer",
      "Capsicum",
      "Red paprika",
      "Mint mayo",
      "Chat masala",
      "Coriander leaves"
    ],
    diet: "vegetarian",
  ),
];

// Add these constants
const double INITIAL_WALLET_BALANCE = 2000.0;
const String INSUFFICIENT_BALANCE_MESSAGE =
    "Sorry, you don't have enough balance in your wallet for {ITEM}. Your current balance is ₹{BALANCE}";
const String WALLET_CHARGE_MESSAGE =
    "You've selected: {ITEM} (₹{PRICE})\nWould you like me to charge ₹{PRICE} from your wallet? Please confirm (yes/no).";
const String WALLET_CONFIRMATION_MESSAGE =
    "Great! Charged ₹{PRICE} from your wallet.\nBalance remaining: ₹{BALANCE}\n\nProcessing your order now...";
