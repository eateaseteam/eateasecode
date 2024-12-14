import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RestaurantDataManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'restaurants';

  /// Fetches reservations for a specific restaurant
  Stream<QuerySnapshot> getReservationsStream(String restaurantId) {
    return _firestore
        .collection(collectionName)
        .doc(restaurantId)
        .collection('reservations')
        .orderBy('bookingTimestamp', descending: true)
        .snapshots();
  }

  /// Fetches reservations for a specific restaurant with a specific status
  Stream<QuerySnapshot> getReservationsStreamByStatus(String restaurantId, String status) {
    return _firestore
        .collection(collectionName)
        .doc(restaurantId)
        .collection('reservations')
        .where('status', isEqualTo: status)
        .orderBy('bookingTimestamp', descending: true)
        .snapshots();
  }

  /// Updates the status of a reservation
  Future<void> updateReservationStatus(String restaurantId, String reservationId, String newStatus) async {
    await _firestore
        .collection(collectionName)
        .doc(restaurantId)
        .collection('reservations')
        .doc(reservationId)
        .update({'status': newStatus});
  }

  /// Fetches random popular food items from Firestore.
  Future<List<Map<String, dynamic>>> getRandomPopularFoods(int count) async {
    final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
    List<Map<String, dynamic>> allFoods = [];

    for (var doc in snapshot.docs) {
      final restaurant = doc.data() as Map<String, dynamic>;
      final menuItemsSnapshot = await doc.reference.collection('menuItems').get();

      for (var item in menuItemsSnapshot.docs) {
        allFoods.add({
          ...item.data(),
          'restaurantId': doc.id,
          'restaurantName': restaurant['name'],
          'restaurantData': restaurant,
        });
      }
    }

    allFoods.shuffle(Random());
    return allFoods.take(count).toList();
  }

  /// Returns a stream of restaurants.
  Stream<QuerySnapshot> getRestaurantsStream() {
    return _firestore.collection(collectionName).snapshots();
  }

  /// Fetches a single restaurant by its ID, including menu items and GCash number.
  Future<Map<String, dynamic>?> getRestaurantById(String id) async {
    final DocumentSnapshot doc = await _firestore.collection(collectionName).doc(id).get();
    if (!doc.exists) return null;

    final restaurant = doc.data() as Map<String, dynamic>;
    final menuItemsSnapshot = await doc.reference.collection('menuItems').get();
    final menuItems = menuItemsSnapshot.docs.map((item) => item.data()).toList();

    return {
      ...restaurant,
      'id': doc.id,
      'menuItems': menuItems,
      'phoneNumber': restaurant['phoneNumber'] ?? 'GCash number not available',
    };
  }

  /// Adds a new reservation to the restaurant's reservations subcollection
  Future<void> addReservation(String restaurantId, Map<String, dynamic> reservationData) async {
    final reservationWithTimestamp = {
      ...reservationData,
      'bookingTimestamp': FieldValue.serverTimestamp(),
    };

    // Ensure all string fields are not null
    reservationWithTimestamp.forEach((key, value) {
      if (value is String?) {
        reservationWithTimestamp[key] = value ?? '';
      }
    });

    await _firestore.collection(collectionName).doc(restaurantId).collection('reservations').add(reservationWithTimestamp);
  }

  /// Fetches reservations for a specific restaurant
  Future<List<Map<String, dynamic>>> getReservationsForRestaurant(String restaurantId) async {
    final QuerySnapshot reservationsSnapshot = await _firestore
        .collection(collectionName)
        .doc(restaurantId)
        .collection('reservations')
        .orderBy('bookingTimestamp', descending: true)
        .get();

    return reservationsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<DocumentSnapshot> getReservationDetails(String restaurantId, String reservationId) async {
    return await _firestore
        .collection(collectionName)
        .doc(restaurantId)
        .collection('reservations')
        .doc(reservationId)
        .get();
  }

  Future<List<Map<String, dynamic>>> searchMenuItems(String query) async {
    query = query.toLowerCase();
    final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
    List<Map<String, dynamic>> results = [];

    for (var doc in snapshot.docs) {
      final restaurant = doc.data() as Map<String, dynamic>;
      final menuItemsSnapshot = await doc.reference.collection('menuItems').get();

      for (var item in menuItemsSnapshot.docs) {
        final menuItem = item.data();
        if (menuItem['name'].toString().toLowerCase().contains(query)) {
          results.add({
            ...menuItem,
            'restaurantId': doc.id,
            'restaurantName': restaurant['name'],
          });
        }
      }
    }

    return results;
  }

  /// Cancels a reservation
  Future<void> cancelReservation(String restaurantId, String reservationId, String reason) async {
    await _firestore
        .collection(collectionName)
        .doc(restaurantId)
        .collection('reservations')
        .doc(reservationId)
        .update({
      'status': 'cancelled',
      'cancellationReason': reason,
    });
  }
}

