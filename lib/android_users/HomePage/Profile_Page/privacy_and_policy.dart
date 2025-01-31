import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Privacy and Policy',
              style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Privacy'),
              Tab(text: 'Policy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Privacy Tab Content
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'At Eat Ease, your privacy is our priority. We collect personal information such as your name, contact details, and reservation data to provide and improve our services. Your data may be shared with restaurants and trusted third-party providers to ensure a seamless experience.',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'We implement security measures to protect your information, but please note that no system is completely secure. By using Eat Ease, you agree to our data collection and usage practices. For any questions or concerns about your privacy, please contact us at',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
            // Policy Tab Content
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'At Eat Ease, we are committed to providing a reliable and user-friendly service for restaurant bookings and reservations. We expect all users to provide accurate information when making reservations and to honor their bookings.',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'We reserve the right to modify or cancel reservations in cases of misuse or violations of our terms. Users are also responsible for safeguarding their account information and for any activity that occurs under their account. By using Eat Ease, you agree to adhere to these policies and any updates we may implement to improve our services.',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
