import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'connection_controller.dart';
import 'core/accounts_storage/accounts_storage.dart';
import 'core/accounts_storage/models/assets_list.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/token_wallet/get_token_wallet_info.dart';
import 'models/nekoton_exception.dart';
import 'transport/gql_transport.dart';

class AccountsStorageController {
  static AccountsStorageController? _instance;
  late final AccountsStorage _accountsStorage;
  late final ConnectionController _connectionController;
  final _accountsSubject = BehaviorSubject<List<AssetsList>>.seeded([]);

  AccountsStorageController._();

  static Future<AccountsStorageController> getInstance() async {
    if (_instance == null) {
      final instance = AccountsStorageController._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Stream<List<AssetsList>> get accountsStream => _accountsSubject.stream;

  List<AssetsList> get accounts => _accountsSubject.value;

  Future<AssetsList> addAccount({
    required String name,
    required String publicKey,
    required WalletType walletType,
    required int workchain,
  }) async {
    final account = await _accountsStorage.addAccount(
      name: name,
      publicKey: publicKey,
      walletType: walletType,
      workchain: workchain,
    );

    _accountsSubject.add(await _accountsStorage.accounts);

    return account;
  }

  Future<AssetsList> renameAccount({
    required String address,
    required String name,
  }) async {
    final account = await _accountsStorage.renameAccount(
      address: address,
      name: name,
    );

    _accountsSubject.add(await _accountsStorage.accounts);

    return account;
  }

  Future<AssetsList?> removeAccount(String address) async {
    final account = await _accountsStorage.removeAccount(address);

    _accountsSubject.add(await _accountsStorage.accounts);

    return account;
  }

  Future<AssetsList> addTokenWallet({
    required String address,
    required String rootTokenContract,
  }) async {
    final transport = _connectionController.transport as GqlTransport;

    try {
      await getTokenWalletInfo(
        transport: transport,
        owner: address,
        rootTokenContract: rootTokenContract,
      );
    } catch (err) {
      throw InvalidRootTokenContractException();
    }

    final networkGroup = _connectionController.transport.connectionData.group;

    final account = await _accountsStorage.addTokenWallet(
      address: address,
      rootTokenContract: rootTokenContract,
      networkGroup: networkGroup,
    );

    _accountsSubject.add(await _accountsStorage.accounts);

    return account;
  }

  Future<AssetsList> removeTokenWallet({
    required String address,
    required String rootTokenContract,
  }) async {
    final networkGroup = _connectionController.transport.connectionData.group;

    final account = await _accountsStorage.removeTokenWallet(
      address: address,
      rootTokenContract: rootTokenContract,
      networkGroup: networkGroup,
    );

    _accountsSubject.add(await _accountsStorage.accounts);

    return account;
  }

  Future<void> clearAccountsStorage() async {
    await _accountsStorage.clear();

    _accountsSubject.add(await _accountsStorage.accounts);
  }

  Future<void> _initialize() async {
    _accountsStorage = await AccountsStorage.getInstance();
    _connectionController = await ConnectionController.getInstance();

    _accountsSubject.add(await _accountsStorage.accounts);
  }
}
