import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/splash/screens/splash_screen.dart';
import 'package:ride_sharing_user_app/features/bingo/screens/bingo_client_screen.dart';
import 'package:ride_sharing_user_app/features/bingo/screens/bingo_admin_login_screen.dart';
import 'package:ride_sharing_user_app/features/bingo/screens/bingo_game_screen.dart';
import 'package:ride_sharing_user_app/features/bingo/screens/bingo_history_screen.dart';
import 'package:ride_sharing_user_app/features/bingo/screens/bingo_main_screen.dart';
import 'package:ride_sharing_user_app/features/rifa/screens/rifa_main_screen.dart';
import 'package:ride_sharing_user_app/features/rifa/screens/teimozinha_screen.dart';
import 'package:ride_sharing_user_app/features/rifa/controllers/rifa_controller.dart';

class RouteHelper {
  static const String splash = '/splash';
  static const String bingo = '/bingo';
  static const String bingoClient = '/bingo-client';
  static const String bingoGame = '/bingo-game';
  static const String bingoHistory = '/bingo-history';
  static const String bingoAdmin = '/bingo_admin';
  static const String rifaMain = '/rifa-main';
  static const String teimozinha = '/teimozinha';
  static String getSplashRoute({Map<String,dynamic>? notificationData}) {
    notificationData?.remove('body');
    String userName = (notificationData?['user_name'] ?? '').replaceAll('&','a');
    notificationData?.remove('user_name');

    return '$splash?notification=${jsonEncode(notificationData)}&userName=$userName';
  }
  static List<GetPage> routes = [
    GetPage(name: splash, page: () => SplashScreen(
        notificationData: Get.parameters['notification'] == null ?
        null :
        jsonDecode(Get.parameters['notification']!),
        userName: Get.parameters['userName']?.replaceAll('a', '&')
    )),
    GetPage(name: bingo, page: () => const BingoMainScreen()),
    GetPage(name: bingoClient, page: () => const BingoClientScreen()),
    GetPage(name: bingoGame, page: () => const BingoGameScreen()),
    GetPage(name: bingoHistory, page: () => const BingoHistoryScreen()),
    GetPage(name: bingoAdmin, page: () => const BingoAdminLoginScreen()),
    GetPage(
      name: rifaMain, 
      page: () => const RifaMainScreen(),
      binding: BindingsBuilder(() {
        Get.put(RifaController());
      }),
    ),
    GetPage(
      name: teimozinha, 
      page: () => const TeimozinhaScreen(),
      binding: BindingsBuilder(() {
        Get.put(RifaController());
      }),
    ),
  ];

  static void goPageAndHideTextField(BuildContext context, Widget page){
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    currentFocus.requestFocus(FocusNode());
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    Future.delayed(const Duration(milliseconds: 300)).then((_){
      Get.to(() => page);

    });

  }

}