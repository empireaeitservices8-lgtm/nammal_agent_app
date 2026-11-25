import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRepository(apiClient);
});

class WalletRepository {
  final ApiClient _apiClient;

  WalletRepository(this._apiClient);

  Future<WalletModel> getBalance() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.walletBalance);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{'balance': 0};
      return WalletModel.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch wallet balance: $e');
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.transactions);
      final data = response.data;
      if (data is List) {
        return data.map((e) => TransactionModel.fromJson(e)).toList();
      } else if (data is Map && data['transactions'] is List) {
        return (data['transactions'] as List)
            .map((e) => TransactionModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch transactions: $e');
    }
  }

  List<CoinPackageModel> getCoinPackages() {
    return [
      CoinPackageModel(id: 'pkg_1', coins: 100, price: 99.0, discountText: 'Popular'),
      CoinPackageModel(id: 'pkg_2', coins: 250, price: 229.0, discountText: 'Save 10%'),
      CoinPackageModel(id: 'pkg_3', coins: 500, price: 449.0, discountText: 'Best Value'),
      CoinPackageModel(id: 'pkg_4', coins: 1000, price: 849.0, discountText: 'Save 20%'),
    ];
  }
}
