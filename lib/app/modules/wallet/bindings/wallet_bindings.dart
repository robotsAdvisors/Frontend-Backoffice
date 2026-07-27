// wallet_bindings.dart
import 'dart:async';
import 'package:flutter/services.dart';

/// Clase que expone los métodos de la wallet a Flutter.
/// Usa MethodChannel para comunicarse con código nativo o backend.
class WalletBindings {
  static const MethodChannel _channel = MethodChannel('wallet_channel');

  /// Inicializa la wallet con un usuario o token.
  static Future<bool> initWallet(String userId) async {
    final bool result = await _channel.invokeMethod('initWallet', {
      'userId': userId,
    });
    return result;
  }

  /// Obtiene el balance actual de la wallet.
  static Future<double> getBalance() async {
    final double balance = await _channel.invokeMethod('getBalance');
    return balance;
  }

  /// Realiza una transacción de la wallet.
  static Future<String> sendTransaction({
    required String to,
    required double amount,
  }) async {
    final String txId = await _channel.invokeMethod('sendTransaction', {
      'to': to,
      'amount': amount,
    });
    return txId;
  }

  /// Lista las transacciones recientes.
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final List<dynamic> transactions =
        await _channel.invokeMethod('getTransactions');
    return transactions.cast<Map<String, dynamic>>();
  }
}
