import 'package:flutter/material.dart';

/// Lets ApiService redirect to the login screen on a 401 response,
/// without the service layer needing a BuildContext passed in from every call site.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
