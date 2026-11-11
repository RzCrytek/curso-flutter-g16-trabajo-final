import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void goToRoot() {
  navigatorKey.currentState?.popUntil((route) => route.isFirst);
}
