import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RestaurantDataManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'restaurants';

  final List<Map<String, dynamic>> hardcodedRestaurants = [
    {
      'name': 'Ghetto Plates',
      'image': 'lib/assets/food_images/sample_food.png',
      'description': 'Lilipapang Galunggong Inihahain',
      'location': 'Liwayway Dalingan Romblon',
      'address': '023 Pasilio Burgos st, Dalingan 5505 Philippines',
      'perGuestPrice': 150.0,
      'menuCategories': [
        {
          'name': 'Appetizers',
          'items': [
            {
              'name': 'Lumpia',
              'description': 'Filipino spring rolls',
              'price': 80.0,
              'image': 'lib/assets/food_images/sample_food.png',
            },
            {
              'name': 'Sinigang na Hipon',
              'description': 'Shrimp in sour tamarind soup',
              'price': 150.0,
              'image': 'lib/assets/food_images/sample_food.png',
            },
          ],
        },
        {
          'name': 'Main Courses',
          'items': [
            {
              'name': 'Adobo',
              'description': 'Chicken or pork stewed in soy sauce and vinegar',
              'price': 180.0,
              'image': 'lib/assets/food_images/sample_food.png',
            },
            {
              'name': 'Kare-Kare',
              'description': 'Oxtail stew in peanut sauce',
              'price': 220.0,
              'image': 'lib/assets/food_images/sample_food.png',
            },
          ],
        },
        {
          'name': 'Desserts',
          'items': [
            {
              'name': 'Halo-Halo',
              'description': 'Mixed sweets with shaved ice and milk',
              'price': 100.0,
              'image': 'lib/assets/food_images/sample_food.png',
            },
            {
              'name': 'Leche Flan',
              'description': 'Filipino caramel custard',
              'price': 80.0,
              'image': 'lib/assets/food_images/sample_food.png',
            },
          ],
        },
      ],
      'featuredItems': [
        {
          'name': 'Pork Sisig',
          'description': 'With Rice',
          'price': 80.0,
          'image': 'lib/assets/food_images/sample_food.png',
        },
        {
          'name': 'Bopis Sisig',
          'description': 'With Rice',
          'price': 80.0,
          'image': 'lib/assets/food_images/sample_food.png',
        },
        {
          'name': 'Lechon Kawali',
          'description': 'Crispy Pork Belly',
          'price': 95.0,
          'image': 'lib/assets/food_images/sample_food.png',
        },
      ],
      'about': 'The Sizzling Zone offers delicious Filipino cuisine with sizzling dishes and local favorites, including our famous Pork Sisig and Bopis Sisig, all served in a welcoming atmosphere. Experience the flavors of the Philippines at Ghetto Plates!',
      'openingHours': {
        'Monday': '11:00 AM - 10:00 PM',
        'Tuesday': '11:00 AM - 10:00 PM',
        'Wednesday': '11:00 AM - 10:00 PM',
        'Thursday': '11:00 AM - 10:00 PM',
        'Friday': '11:00 AM - 11:00 PM',
        'Saturday': '10:00 AM - 11:00 PM',
        'Sunday': '10:00 AM - 9:00 PM',
      },
    },
    {
      'name': 'JCM',
      'image': 'lib/assets/restaurants_logo/jcm_logo.png',
      'description': 'Fresh Seafood Delights',
      'location': 'Poblacion, Romblon',
      'address': '456 Main St, Poblacion, Romblon 5500',
      'perGuestPrice': 200.0,
      'menuCategories': [
        {
          'name': 'Seafood',
          'items': [
            {
              'name': 'Grilled Tuna',
              'description': 'Fresh catch of the day',
              'price': 120.0,
              'image': 'lib/assets/restaurants_logo/jcm_logo.png',
            },
            {
              'name': 'Seafood Platter',
              'description': 'Assorted seafood',
              'price': 250.0,
              'image': 'lib/assets/restaurants_logo/jcm_logo.png',
            },
          ],
        },
        {
          'name': 'Grilled Specialties',
          'items': [
            {
              'name': 'BBQ Pork Ribs',
              'description': 'Tender pork ribs with BBQ sauce',
              'price': 180.0,
              'image': 'lib/assets/restaurants_logo/jcm_logo.png',
            },
            {
              'name': 'Grilled Chicken',
              'description': 'Herb-marinated grilled chicken',
              'price': 150.0,
              'image': 'lib/assets/restaurants_logo/jcm_logo.png',
            },
          ],
        },
        {
          'name': 'Desserts',
          'items': [
            {
              'name': 'Mango Float',
              'description': 'Layered mango dessert',
              'price': 60.0,
              'image': 'lib/assets/restaurants_logo/jcm_logo.png',
            },
            {
              'name': 'Buko Pandan',
              'description': 'Coconut and pandan jelly dessert',
              'price': 50.0,
              'image': 'lib/assets/restaurants_logo/jcm_logo.png',
            },
          ],
        },
      ],
      'featuredItems': [
        {
          'name': 'Grilled Tuna',
          'description': 'Fresh catch of the day',
          'price': 120.0,
          'image': 'lib/assets/restaurants_logo/jcm_logo.png',
        },
        {
          'name': 'Seafood Platter',
          'description': 'Assorted seafood',
          'price': 250.0,
          'image': 'lib/assets/restaurants_logo/jcm_logo.png',
        },
        {
          'name': 'Mango Float',
          'description': 'Sweet dessert',
          'price': 60.0,
          'image': 'lib/assets/restaurants_logo/jcm_logo.png',
        },
      ],
      'about': 'JCM offers the freshest seafood in Romblon. Our menu changes daily based on the local fishermen\'s catch. Experience the true taste of the sea at JCM!',
      'openingHours': {
        'Monday': '11:00 AM - 9:00 PM',
        'Tuesday': '11:00 AM - 9:00 PM',
        'Wednesday': '11:00 AM - 9:00 PM',
        'Thursday': '11:00 AM - 9:00 PM',
        'Friday': '11:00 AM - 10:00 PM',
        'Saturday': '10:00 AM - 10:00 PM',
        'Sunday': '10:00 AM - 9:00 PM',
      },
    },
  ];

  Future<void> uploadRestaurantsIfNotExist() async {
    final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
    if (snapshot.docs.isEmpty) {
      for (var restaurant in hardcodedRestaurants) {
        await _firestore.collection(collectionName).add(restaurant);
      }
      print('Restaurants uploaded to Firestore.');
    } else {
      print('Restaurants already exist in Firestore.');
    }
  }

  Future<List<Map<String, dynamic>>> getRandomPopularFoods(int count) async {
    final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
    List<Map<String, dynamic>> allFoods = [];

    for (var doc in snapshot.docs) {
      final restaurant = doc.data() as Map<String, dynamic>;
      for (var category in restaurant['menuCategories']) {
        for (var item in category['items']) {
          allFoods.add({
            ...item,
            'restaurantName': restaurant['name'],
            'restaurantData': restaurant,
          });
        }
      }
    }

    allFoods.shuffle(Random());
    return allFoods.take(count).toList();
  }

  Stream<QuerySnapshot> getRestaurantsStream() {
    return _firestore.collection(collectionName).snapshots();
  }
}

