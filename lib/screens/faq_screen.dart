
import 'package:flutter/material.dart';
import 'package:signalbait_mobile/data/faq.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  // A Flutter widget's build() method must return a widget,
  // but that widget can be any suitable type of widget.

  @override
  Widget build(BuildContext context) {
    // This returns a scrollable list view for the UI.
    return ListView(
      // children -> specifies which child widgets to include.
      children: [
        for (final qna in FAQ)
          ExpansionTile(
            title: Text(qna.question),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(qna.answer),
              ),
            ],
          ),
      ],
    );
  }
}
