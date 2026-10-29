import 'package:get/get.dart';

enum HomeTab { search, rides, drive, messages }

/// Aba selecionada na navegação inferior.
class HomeController extends GetxController {
  final tab = HomeTab.search.obs;

  void select(HomeTab value) => tab.value = value;

  /// Pílula "⇅ Passageiro / Motorista" alterna entre buscar e dirigir.
  void toggleMode() => tab.value = tab.value == HomeTab.drive ? HomeTab.search : HomeTab.drive;
}
