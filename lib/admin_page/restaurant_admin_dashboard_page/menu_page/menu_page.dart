import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> categories = ['All', 'Pork', 'Chicken', 'Seafood', 'Desserts', 'Beverages'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu Management',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Add menu item logic
                },
                icon: Icon(Icons.add),
                label: Text('Add Menu Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.orange,
                  tabs: categories
                      .map((category) => Tab(
                    text: category,
                    height: 48,
                  ))
                      .toList(),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildMenuTable(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        dataRowHeight: 80,
        columns: [
          DataColumn(
            label: Text(
              'Menu Item',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Price',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Description',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Type',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Image',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: [
          _buildMenuItemRow(
            'Crispy Pork Belly',
            '₱299.00',
            'Crispy fried pork belly with special sauce',
            'Main Course',
            'pork_belly.jpg',
          ),
          _buildMenuItemRow(
            'Chicken Adobo',
            '₱249.00',
            'Traditional Filipino chicken adobo',
            'Main Course',
            'chicken_adobo.jpg',
          ),
          // Add more rows as needed
        ],
      ),
    );
  }

  DataRow _buildMenuItemRow(
      String name,
      String price,
      String description,
      String type,
      String image,
      ) {
    return DataRow(
      cells: [
        DataCell(Text(name)),
        DataCell(Text(price)),
        DataCell(
          Container(
            width: 200,
            child: Text(
              description,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(type)),
        DataCell(
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey[400]),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.orange),
                onPressed: () {
                  // Edit logic
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[400]),
                onPressed: () {
                  // Delete logic
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}