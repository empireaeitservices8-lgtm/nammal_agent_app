import 'wallet_model.dart';
import 'transaction_model.dart';

enum WalletStatus { initial, loading, loaded, error }

class WalletState {
  final WalletStatus status;
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final List<CoinPackageModel> packages;
  final String? errorMessage;

  const WalletState({
    this.status = WalletStatus.initial,
    required this.wallet,
    this.transactions = const [],
    this.packages = const [],
    this.errorMessage,
  });

  WalletState copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    List<TransactionModel>? transactions,
    List<CoinPackageModel>? packages,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      packages: packages ?? this.packages,
      errorMessage: errorMessage,
    );
  }
}
