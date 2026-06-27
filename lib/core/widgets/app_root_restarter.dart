import 'package:flutter/material.dart';

/// Rebuilds the entire app subtree when [restart] is called (e.g. from global error UI).
class AppRootRestarter extends StatefulWidget {
  const AppRootRestarter({super.key, required this.child});

  final Widget child;

  static AppRootRestarterState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppRootRestarterState>();
  }

  @override
  State<AppRootRestarter> createState() => AppRootRestarterState();
}

class AppRootRestarterState extends State<AppRootRestarter> {
  Key _childKey = UniqueKey();

  void restart() {
    setState(() => _childKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _childKey, child: widget.child);
  }
}
