import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/carona_api.dart';
import 'api/geocoding.dart';
import 'app/routes.dart';
import 'config.dart';
import 'services/auth_service.dart';
import 'services/driven_rides_service.dart';
import 'services/messages_service.dart';
import 'services/places_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final prefs = await SharedPreferences.getInstance();

  // Dependências globais, disponíveis via Get.find() em qualquer controller.
  final api = Get.put(CaronaApi(ApiClient(AppConfig.apiUrl)), permanent: true);
  final geocoding = Get.put(Geocoding(), permanent: true);
  final auth = Get.put(AuthService(api, prefs), permanent: true);
  Get.put(PlacesService(prefs, geocoding), permanent: true);
  Get.put(MessagesService(api), permanent: true);
  Get.put(DrivenRidesService(api, prefs), permanent: true);

  runApp(CaronaApp(initialRoute: auth.isLoggedIn ? Routes.home : Routes.login));
}

class CaronaApp extends StatelessWidget {
  final String initialRoute;

  const CaronaApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Carona Universitária',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: initialRoute,
      getPages: appPages,
      defaultTransition: Transition.cupertino,
    );
  }
}
