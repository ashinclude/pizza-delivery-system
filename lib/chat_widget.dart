import 'package:aifoodsystem/model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernMessageBubble extends StatelessWidget {
  final Message message;
  final Color userAgentColor;
  final Color kitchenAgentColor;
  final Color deliveryAgentColor;

  const ModernMessageBubble({
    super.key,
    required this.message,
    required this.userAgentColor,
    required this.kitchenAgentColor,
    required this.deliveryAgentColor,
  });

  Color _getAgentColor() {
    switch (message.agentType) {
      case "kitchen_agent":
        return kitchenAgentColor;
      case "delivery_agent":
        return deliveryAgentColor;
      case "user_agent":
        return userAgentColor;
      default:
        return Colors.grey;
    }
  }

@override
  Widget build(BuildContext context) {
    final isUser = message.role == "user";
    final agentColor = _getAgentColor();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.withOpacity(0.2) : Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUser ? Colors.transparent : agentColor.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ],
              ),
              child: Text(
                message.content.replaceAll('₹', '₹ ').replaceAll('**', ''),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WalletBalance extends StatelessWidget {
  final double balance;
  final Color? backgroundColor;
  final Color? textColor;

  const WalletBalance({
    super.key,
    required this.balance,
    this.backgroundColor,
    this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wallet, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '₹ ${balance.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class StatusDialog extends StatelessWidget {
  final OrderStatus currentStatus;
  final Map<String, String> agentOutputs;

  const StatusDialog({
    super.key,
    required this.currentStatus,
    required this.agentOutputs,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Order Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Status: ${currentStatus.toString().split('.').last}'),
          const SizedBox(height: 16),
          if (agentOutputs.isNotEmpty) ...[
            const Text('Agent Outputs:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(agentOutputs.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(entry.value),
                    const SizedBox(height: 8),
                  ],
                ))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
