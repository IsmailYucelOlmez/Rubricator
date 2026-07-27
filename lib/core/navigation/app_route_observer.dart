import 'package:flutter/material.dart';

/// Shared [RouteObserver] for pages that need lifecycle hooks (e.g. unfocus).
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
