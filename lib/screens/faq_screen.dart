import 'package:flutter/material.dart';
import 'package:signalbait_mobile/data/faq.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const Color _background = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF151515);
  static const Color _green = Color(0xFF80FF80);
  static const Color _muted = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Help & FAQ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find answers to common questions about SignalBait.',
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // FAQ introduction card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.support_agent,
                  color: _green,
                  size: 30,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need some help?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Browse the questions below to learn more '
                        'about SignalBait and its analysis results.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          // Expandable FAQ cards
          ...FAQ.map(
            (qna) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: _green.withValues(alpha: 0.06),
                  highlightColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    18,
                  ),
                  iconColor: _green,
                  collapsedIconColor: _muted,
                  title: Text(
                    qna.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                      child: Text(
                        qna.answer,
                        style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              'SignalBait • Help Center',
              style: TextStyle(
                color: _muted.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
