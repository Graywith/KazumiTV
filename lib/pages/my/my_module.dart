import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/pages/my/my_page.dart';

final myModule = createModule(
  path: '/my',
  register: (c) {
    c.route(
      '/',
      guards: isTv ? [(state) => '/settings/player'] : [],
      transition: TransitionType.none,
      child: (context, state) => MyPage(controller: inject<MyController>()),
    );
  },
);
