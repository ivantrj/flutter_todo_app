import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ToDoList extends StatefulWidget {
  const ToDoList({super.key});

  @override
  State<ToDoList> createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      material: (context, platform) => MaterialScaffoldData(
        drawer: const Drawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
      cupertino: (context, platform) => CupertinoPageScaffoldData(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('To Do List'),
        ),
      ),
      appBar: PlatformAppBar(),
      bottomNavBar: PlatformNavBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(PlatformIcons(context).home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(PlatformIcons(context).settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
