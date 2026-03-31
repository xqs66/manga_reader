import 'package:get/get.dart';
import 'package:manga_reader/pages/home_page_state.dart';

class HomePageController extends GetxController {
  HomePageState state = HomePageState();

  final String homePageId = 'home_page';
  final String bottomBarId = 'bottom_bar';

  void handleBottomBarTabIndexChanged(int index) {
    state.pageIndex = index;
    update([homePageId, bottomBarId]);
  }

  void toggleShowBottomBar() {
    state.showBottomBar = !state.showBottomBar;
    update([bottomBarId]);
  }
}
