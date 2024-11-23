import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _loadData();
  }

  void _loadData() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildShimmerEffect() : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[300],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order List',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              // Implement search functionality
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      )),
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Reservation ID:', order.id.toString()),
              Divider(),
              _buildInfoRow('Customer name:', order.customerName),
              Divider(),
              _buildMenuItemsTable(order.items),
              Divider(),
              _buildInfoRow('Total Price:', '\$${order.total.toStringAsFixed(2)}'),
              SizedBox(height: 8),
              _buildStatusBadge(order.status), // Status badge
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsTable(List<MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'Menu Item',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Quantity',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  item.name,
                  style: GoogleFonts.poppins(),
                ),
              ),
              Expanded(
                child: Text(
                  item.quantity.toString(),
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.approved:
        color = Colors.green;
        text = 'Approved';
        break;
      case OrderStatus.completed:
        color = Colors.blue;
        text = 'Completed';
        break;
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class MenuItem {
  final String name;
  final int quantity;

  MenuItem({required this.name, required this.quantity});
}

class Order {
  final int id;
  final String customerName;
  final List<MenuItem> items;
  final double total;
  final OrderStatus status; // New status property

  Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status, // Include status in the constructor
  });
}

enum OrderStatus {
  approved,
  completed,
  pending,
  cancelled,
}

// Sample data
final List<Order> _orders = [
  Order(
    id: 1001,
    customerName: 'John Doe',
    items: [
      MenuItem(name: 'Burger', quantity: 2),
      MenuItem(name: 'Fries', quantity: 1),
    ],
    total: 25.99,
    status: OrderStatus.approved, // Add status
  ),
  Order(
    id: 1002,
    customerName: 'Jane Smith',
    items: [
      MenuItem(name: 'Pizza', quantity: 1),
      MenuItem(name: 'Soda', quantity: 2),
    ],
    total: 18.50,
    status: OrderStatus.pending, // Add status
  ),
  Order(
    id: 1003,
    customerName: 'Bob Johnson',
    items: [
      MenuItem(name: 'Salad', quantity: 1),
      MenuItem(name: 'Water', quantity: 1),
    ],
    total: 12.75,
    status: OrderStatus.completed, // Add status
  ),
];