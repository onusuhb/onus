import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onus/UserDetailsPage.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchEmail = '';
  String _selectedRole = 'All';

  Future<void> _deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

Future<void> _changeUserRole(String userId, String currentRole) async {
  if (currentRole == 'Company') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You can't change the role of a Company user."),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  String? newRole = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Change User Role"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Customer', 'Admin']
              .where((role) => role != currentRole)
              .map((role) => ListTile(
                    title: Text(role),
                    onTap: () => Navigator.pop(context, role),
                  ))
              .toList(),
        ),
      );
    },
  );

  if (newRole != null) {
    try {
      await _firestore.collection('users').doc(userId).update({'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role updated to $newRole')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e')),
      );
    }
  }
}

  Future<void> _deleteAllUsers() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
            'Are you sure you want to permanently delete ALL users from the database?\n\n⚠️ This cannot be undone.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
        for (var doc in usersSnapshot.docs) {
          await doc.reference.delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All users deleted from Firestore')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All Users',
            onPressed: _deleteAllUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Search by Email",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchEmail = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedRole,
                  items: ['All', 'Admin', 'Customer', 'Company']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                var users = snapshot.data!.docs.where((doc) {
                  String email = (doc['email'] ?? '').toLowerCase();
                  String role = doc['role'] ?? '';
                  return email.contains(_searchEmail) &&
                      (_selectedRole == 'All' || role == _selectedRole);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No matching users"));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    String userId = user.id;
                    String fullName = user['fullName'] ?? 'Unknown';
                    String email = user['email'] ?? 'No Email';
                    String role = user['role'] ?? 'Customer';
                    bool accepted = user['accepted'] ?? true;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: (role == 'Company' && !accepted) ? Colors.red[100] : null,
                      child: ListTile(
                        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => UserDetailsPage(userId: userId),
    ),
  );
},

                        leading: const Icon(Icons.person, color: Colors.teal),
                        title: Text(
                          fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Email: $email\nRole: $role"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteUser(userId);
                            } else if (value == 'change_role') {
                              _changeUserRole(userId, role);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'change_role', child: Text('Change Role')),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete User', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
