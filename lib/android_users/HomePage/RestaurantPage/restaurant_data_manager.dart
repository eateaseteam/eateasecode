import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RestaurantDataManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'restaurants';

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
}

