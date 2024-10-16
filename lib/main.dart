import 'package:flutter/material.dart';
import 'package:http_interceptor/http/intercepted_http.dart';
import 'package:wallet_test/common/factory/wallet_service_factory.dart';
import 'package:wallet_test/data/library_storage.dart';
import 'package:wallet_test/data/logger_interceptor.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/feature/import_wallet_screen.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

void main() {
  final libraryStorage = LibraryStorage()..init();

  final core = TrustWalletCore(libraryStorage.library);

  final http = InterceptedHttp.build(interceptors: [
    LoggerInterceptor(),
  ]);

  final walletRepository = WalletRepository(
    libraryStorage: libraryStorage,
    core: core,
  );

  final tokenService = WalletServiceFactory(
    walletRepository: walletRepository,
    http: http,
  );

  runApp(
    DependencyScope(
      libraryStorage: libraryStorage,
      walletRepository: walletRepository,
      serviceFactory: tokenService,
      core: core,
      http: http,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Crypto Test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ImportWalletScreen(),
      );
}
