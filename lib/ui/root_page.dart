import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding/constants.dart';
import 'package:flutter_onboarding/models/plants.dart';
import 'package:flutter_onboarding/ui/scan_page.dart';
import 'package:flutter_onboarding/ui/screens/cart_page.dart';
import 'package:flutter_onboarding/ui/screens/favorite_page.dart';
import 'package:flutter_onboarding/ui/screens/home_page.dart';
import 'package:flutter_onboarding/ui/screens/profile_page.dart';
import 'package:page_transition/page_transition.dart';

class RootPage extends StatefulWidget {
  final String userId; // Add userId parameter

  const RootPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  List<Plant> favorites = [];
  List<Plant> myCart = [];
  int _bottomNavIndex = 0;

  // Example: A userId that would be passed to the HomePage

  //List of the pages
  List<Widget> _widgetOptions() {
    return [
      HomePage(userId: widget.userId), // Pass userId to the HomePage
      // FavoritePage(favoritedPlants: favorites),
      // CartPage(addedToCartPlants: myCart),
      const ProfilePage(),
    ];
  }

  // List of the pages icons
  List<IconData> iconList = [
    Icons.home,
    Icons.favorite,
    Icons.shopping_cart,
    Icons.person,
  ];

  // List of the pages titles
  List<String> titleList = [
    'Home',
    'Favorite',
    'Cart',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titleList[_bottomNavIndex],
              style: TextStyle(
                color: Constants.blackColor,
                fontWeight: FontWeight.w500,
                fontSize: 24,
              ),
            ),
            Icon(Icons.notifications, color: Constants.blackColor, size: 30.0),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.0,
      ),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: _widgetOptions(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final shouldRefresh = await Navigator.push(
            context,
            PageTransition(
                child: ScanPage(userId: widget.userId),
                type: PageTransitionType.bottomToTop),
          );

          if (shouldRefresh == true && _bottomNavIndex == 0) {
            setState(() {}); // Force rebuild and HomePage will reload
          }
        },
        child: Image.asset('assets/images/code-scan-two.png', height: 30.0),
        backgroundColor: Constants.primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        splashColor: Constants.primaryColor,
        activeColor: Constants.primaryColor,
        inactiveColor: Colors.black.withOpacity(.5),
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }
}
