import 'package:flutter/material.dart';
import 'package:grocermate/screens/home_screen.dart';
import 'package:grocermate/screens/profile_screen.dart';
import 'package:grocermate/screens/your_lists_screen.dart';
import 'package:grocermate/screens/community_screen.dart'; // Import the new screen
import 'friends_screen.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const MainNavigation({Key? key, required this.onThemeToggle})
      : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  void _onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onNavigateToLists: () => _onNavigate(1), 
        onNavigateToFriends: () => _onNavigate(2),
        onNavigateToCommunity: () => _onNavigate(3), // Pass the new callback
      ),
      const YourListsScreen(),
      const FriendsScreen(),
      const CommunityScreen(), // Add CommunityScreen
      ProfileScreen(
        onThemeToggle: widget.onThemeToggle,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              const Color(0xFF81C784).withOpacity(0.1),
              const Color(0xFF388E3C).withOpacity(0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavigate,
          type: BottomNavigationBarType.fixed, // Important for more than 3 items
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF388E3C),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Your Lists',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Friends',
            ),
            BottomNavigationBarItem( // New Community Item
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
