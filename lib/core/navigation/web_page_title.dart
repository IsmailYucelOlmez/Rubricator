import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Sets the browser tab title to [label] while this widget is on screen.
///
/// Dynamic per-page titles (e.g. a book's name, or the active search query)
/// are a web-only concern — on other platforms this is a plain passthrough,
/// so it never touches the Android task-switcher label or iOS app title.
class WebPageTitle extends StatelessWidget {
  const WebPageTitle({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Title(
      title: label,
      color: Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}
