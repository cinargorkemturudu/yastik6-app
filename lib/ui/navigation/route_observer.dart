import 'package:flutter/widgets.dart';
import 'package:yastik_alti/core/app_log.dart';

class AppRouteObserver extends RouteObserver<ModalRoute<dynamic>> {

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    final screenName = route.settings.name;
    if (screenName != null) {
      AppLog.insight('screen_viewed', metadata: {'screen': screenName, 'action': 'push'});
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    final screenName = route.settings.name;
    if (screenName != null) {
      AppLog.insight('screen_viewed', metadata: {'screen': screenName, 'action': 'return'});
    }
  }
}

final AppRouteObserver routeObserver = AppRouteObserver();