import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onus/AddServicePage.dart';
import 'package:onus/AddServiceRandomPage.dart';
import 'package:onus/ManageServicesPage.dart';
import 'package:onus/ProfileManagementPage.dart';
import 'package:onus/ManageCustomerBookingsPage.dart';
import 'package:onus/ManageCompanyBookingsPage.dart';
import 'package:onus/ManageUsersPage.dart';
import 'package:onus/authentication/login_screen.dart';
import 'package:onus/MyBookingsPage.dart';
import 'package:onus/AllBookingsPage.dart';
import 'package:onus/StatisticsPage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userType = "";
  bool _isApproved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userType = userDoc['role'] ?? "Customer";
          _isApproved = userDoc['accepted'] ?? false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1.2,
                ),
                children: _buildDashboardTiles(context),
              ),
            ),
    );
  }

  List<Widget> _buildDashboardTiles(BuildContext context) {
    List<Widget> tiles = [];

    tiles.add(
      _dashboardTile(
        context,
        title: "Profile Management",
        icon: Icons.person,
        destination: ProfileManagementPage(),
      ),
    );

    if (_userType == "Customer") {
      tiles.add(
        _dashboardTile(
          context,
          title: "My Bookings",
          icon: Icons.calendar_today,
          destination: const MyBookingsPage(),
        ),
      );
    }

    if (_userType == "Company") {
      List<Map<String, dynamic>> companyTiles = [
        {
          "title": "Manage Services",
          "icon": Icons.list,
          "destination": ManageServicesPage()
        },
        {
          "title": "Add Service",
          "icon": Icons.add_business,
          "destination": AddServicePage()
        },
        {
          "title": "Add Random Service",
          "icon": Icons.collections,
          "destination": AddServiceRandomPage()
        },
        {
          "title": "Manage Bookings",
          "icon": Icons.assignment,
          "destination": ManageCompanyBookingsPage()
        },
      ];

      for (var tile in companyTiles) {
        tiles.add(
          _dashboardTile(
            context,
            title: tile['title'],
            icon: tile['icon'],
            destination: tile['destination'],
            enabled: _isApproved,
          ),
        );
      }
    }

    if (_userType == "Admin") {
      tiles.addAll([
        _dashboardTile(
          context,
          title: "Manage Users",
          icon: Icons.admin_panel_settings,
          destination: ManageUsersPage(),
        ),
        _dashboardTile(
          context,
          title: "Manage Services",
          icon: Icons.list_alt,
          destination: ManageServicesPage(),
        ),
        _dashboardTile(
          context,
          title: "All Bookings",
          icon: Icons.book_online,
          destination: AllBookingsPage(),
        ),
        _dashboardTile(
          context,
          title: "Statistics",
          icon: Icons.bar_chart,
          destination: StatisticsPage(),
        ),
      ]);
    }

    return tiles;
  }

  Widget _dashboardTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget destination,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wait until admin approval.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
      child: Card(
        elevation: 4,
        color: enabled ? Colors.white : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.teal),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
