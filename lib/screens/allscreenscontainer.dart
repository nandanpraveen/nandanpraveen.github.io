import 'package:flutter/material.dart';
import 'package:outreachapp/screens/alleventspage.dart';
import 'package:outreachapp/screens/myeventspage.dart';
import 'package:outreachapp/screens/postviewpage.dart';

class AllScreensContainer extends StatefulWidget {
  const AllScreensContainer({super.key});

  @override
  State<AllScreensContainer> createState() => _AllScreensContainerState();
}

class _AllScreensContainerState extends State<AllScreensContainer> {
  List<Widget> allNavScreens = const [
    PostViewPage(),
    AllEventsPage(),
    MyEventsPage(),
  ];

  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    Color accentColor = Colors.white;
    return Scaffold(
      body: allNavScreens[currentPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        currentIndex: currentPageIndex,
        onTap: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: "Posts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "All Events",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Me",
          ),
        ],
      ),
    );
  }
}
