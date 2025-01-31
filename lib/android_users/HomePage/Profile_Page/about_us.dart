import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Eat Ease, your go-to app for seamless restaurant bookings and reservations.',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'At Eat Ease, we believe that dining out should be an enjoyable and hassle-free experience. Whether you\'re planning a casual dinner with friends, a romantic evening, or a special celebration, our app is designed to make finding and reserving the perfect table as easy as a few taps.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We partner with a wide range of restaurants to bring you the best dining options, from cozy local favorites to trendy hotspots and fine dining establishments. Our user-friendly platform allows you to explore menus, view restaurant details, and make reservations anytime, anywhere. With Eat Ease, you can manage your bookings, receive instant confirmations, and discover new culinary experiences all in one place.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'At Eat Ease, our mission is to enhance your dining experience by connecting you with great restaurants and simplifying the reservation process. We\'re passionate about food and committed to providing a service that makes dining out convenient, enjoyable, and memorable. Whether you\'re a foodie exploring new tastes or someone looking for a reliable way to book a table, Eat Ease is here to serve you.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for choosing Eat Ease, where every meal begins with a perfect reservation.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
