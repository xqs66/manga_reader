import 'package:get/get.dart';
import 'package:manga_reader/pages/home_page_state.dart';

class HomePageController extends GetxController {
  HomePageState state = HomePageState();

  void handleBottomBarTabIndexChanged(int index) {
    state.pageIndex = index;
    update(['home_page', 'bottom_bar']);
  }
}