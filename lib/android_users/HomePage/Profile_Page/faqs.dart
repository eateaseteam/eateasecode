import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQ\'s',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildFAQItem(
              '1. What is Eat Ease?',
              'Eat Ease is a restaurant booking and reservation app that allows you to easily find and reserve tables at your favorite restaurants. You can also explore new dining options and manage your reservations in one place.',
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              '2. How do I make a reservation?',
              'To make a reservation, simply search for your preferred restaurant in the app, select the date and time, and provide the necessary details. You\'ll receive a confirmation once your reservation is confirmed.',
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              '3. Is there a fee for using Eat Ease?',
              'No, Eat Ease is free to download and use. However, some restaurants may require a deposit or pre-payment for certain reservations, which will be clearly indicated in the app.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}
