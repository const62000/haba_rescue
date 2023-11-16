import 'package:flutter/material.dart';

class ConversationBubble extends StatelessWidget {
  final String text;

  ConversationBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Text(text),
    );
  }
}
