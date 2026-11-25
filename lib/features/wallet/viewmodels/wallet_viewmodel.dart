import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../models/wallet_state.dart';
import '../repositories/wallet_repository.dart';

class WalletViewModel extends Notifier<WalletState> {
  @override
  WalletState build() {
    final repo = ref.read(walletRepositoryProvider);
    Future.microtask(() => loadWallet());
    return WalletState(
      wallet: WalletModel(balance: 0),
      packages: repo.getCoinPackages(),
    );
  }

  WalletRepository get _repository => ref.read(walletRepositoryProvider);

  Future<void> loadWallet() async {
    state = state.copyWith(status: WalletStatus.loading);
    try {
      final wallet = await _repository.getBalance();
      final transactions = await _repository.getTransactions();

      state = state.copyWith(
        status: WalletStatus.loaded,
        wallet: wallet,
        transactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final walletViewModelProvider = NotifierProvider<WalletViewModel, WalletState>(
  WalletViewModel.new,
);
