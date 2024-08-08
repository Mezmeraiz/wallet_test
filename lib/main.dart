import 'package:flutter/material.dart';
import 'package:wallet_test/data/library_storage.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/feature/import_wallet_screen.dart';

void main() {
  final libraryStorage = LibraryStorage()..init();
  final repository = WalletRepository(libraryStorage: libraryStorage);

  runApp(
    DependencyScope(
      libraryStorage: libraryStorage,
      walletRepository: repository,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ImportWalletScreen(),
    );
  }
}
