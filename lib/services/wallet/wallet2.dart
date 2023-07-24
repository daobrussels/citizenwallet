import 'dart:convert';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/indexer/pagination.dart';
import 'package:citizenwallet/services/indexer/signed_request.dart';
import 'package:citizenwallet/services/indexer/status_update_request.dart';
import 'package:citizenwallet/services/wallet/contracts/entrypoint.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/contracts/simple_account.dart';
import 'package:citizenwallet/services/wallet/contracts/simple_account_factory.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/json_rpc.dart';
import 'package:citizenwallet/services/wallet/models/paymaster_data.dart';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WalletService2 {
  BigInt? _chainId;
  late NativeCurrency currency;

  final Client _client = Client();

  final _url = dotenv.get('NODE_URL');
  final _wsurl = dotenv.get('NODE_WS_URL');
  late Web3Client _ethClient;

  final APIService _ipfs = APIService(baseURL: dotenv.get('IPFS_URL'));
  final APIService _indexer = APIService(baseURL: dotenv.get('INDEXER_URL'));
  final APIService _indexerIPFS =
      APIService(baseURL: dotenv.get('INDEXER_IPFS_URL'));

  final APIService _bundlerRPC =
      APIService(baseURL: dotenv.get('ERC4337_RPC_URL'));
  final APIService _paymasterRPC =
      APIService(baseURL: dotenv.get('ERC4337_PAYMASTER_RPC_URL'));
  final String _paymasterType = dotenv.get('ERC4337_PAYMASTER_TYPE');
  final APIService _dataRPC =
      APIService(baseURL: dotenv.get('ERC4337_DATA_URL'));

  final Map<String, String> erc4337Headers = {
    'Origin': dotenv.get('ORIGIN_HEADER')
  };

  late EthPrivateKey _credentials;
  late EthereumAddress _account;

  late StackupEntryPoint _contractEntryPoint;
  late AccountFactory _contractAccountFactory;
  late ERC20Contract _contractToken;
  late SimpleAccount _contractAccount;
  late ProfileContract _contractProfile;

  static final WalletService2 _instance = WalletService2._internal();
  factory WalletService2() => _instance;
  WalletService2._internal();

  EthPrivateKey get credentials => _credentials;
  EthereumAddress get address => _credentials.address;
  EthereumAddress get account => _account;

  /// retrieves the current balance of the address
  Future<String> get balance async =>
      fromUnit(await _contractToken.getBalance(_account.hex));

  /// retrieve chain id
  int get chainId => _chainId != null ? _chainId!.toInt() : 0;

  Future<void> init(
    String privateKey,
    NativeCurrency currency,
    String eaddr,
    String afaddr,
    String taddr,
    String prfaddr,
  ) async {
    _credentials = EthPrivateKey.fromHex(privateKey);

    _ethClient = Web3Client(
      _url,
      _client,
      socketConnector: () =>
          WebSocketChannel.connect(Uri.parse(_wsurl)).cast<String>(),
    );

    _chainId = await _ethClient.getChainId();
    this.currency = currency;

    await _initContracts(eaddr, afaddr, taddr, prfaddr);
  }

  Future<void> _initContracts(
      String eaddr, String afaddr, String taddr, String prfaddr) async {
    _contractEntryPoint = newEntryPoint(chainId, _ethClient, eaddr);
    await _contractEntryPoint.init();

    _contractProfile = newProfileContract(chainId, _ethClient, prfaddr);
    await _contractProfile.init();

    _contractAccountFactory = newAccountFactory(chainId, _ethClient, afaddr);
    await _contractAccountFactory.init();

    _account =
        await _contractAccountFactory.getAddress(_credentials.address.hex);

    _contractToken = newERC20Contract(chainId, _ethClient, taddr);
    await _contractToken.init();

    _contractAccount = newSimpleAccount(chainId, _ethClient, _account.hex);
    await _contractAccount.init();
  }

  /// set profile data
  Future<bool> setProfile(ProfileV1 profile, List<int> image) async {
    try {
      final url = '/profiles/${_account.hex}';

      print('sending to $url');

      final encoded = jsonEncode(
        profile.toJson(),
      );

      final body = SignedRequest(convertStringToUint8List(encoded));

      final sig =
          await compute(generateSignature, (encoded, _credentials.privateKey));

      final resp = await _indexerIPFS.filePut(
        url: url,
        file: image,
        headers: {
          'Authorization': 'Bearer ${dotenv.get('INDEXER_KEY')}',
          'X-Signature': sig,
          'X-Address': address.hex,
        },
        body: body.toJson(),
      );

      print(resp['ipfs_url']);

      // final calldata =
      //     _contractProfile.setCallData(_account.hex, resp['ipfs_url']);

      // final (_, userop) = await prepareUserop(calldata);

      // return submitUserop(userop);
      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return false;
  }

  /// get profile data
  Future<ProfileV1?> getProfile(String addr) async {
    try {
      final url = await _contractProfile.getURL(addr);

      final profileData = await _ipfs.get(url: '/$url');

      return ProfileV1.fromJson(profileData);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  /// fetch erc20 transfer events
  ///
  /// [offset] number of transfers to skip
  ///
  /// [limit] number of transferst to fetch
  ///
  /// [maxDate] fetch transfers up to this date
  Future<(List<TransferEvent>, Pagination)> fetchErc20Transfers({
    required int offset,
    required int limit,
    required DateTime maxDate,
  }) async {
    try {
      final List<TransferEvent> tx = [];

      final url =
          '/logs/transfers/${_contractToken.addr}/${_account.hex}?offset=$offset&limit=$limit&maxDate=${Uri.encodeComponent(maxDate.toUtc().toIso8601String())}';

      final response = await _indexer.get(url: url, headers: {
        'Authorization': 'Bearer ${dotenv.get('INDEXER_KEY')}',
      });

      // convert response array into TransferEvent list
      for (final item in response['array']) {
        tx.add(TransferEvent.fromJson(item));
      }

      return (tx, Pagination.fromJson(response['meta']));
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return (<TransferEvent>[], Pagination.empty());
  }

  /// fetch new erc20 transfer events
  ///
  /// [fromDate] fetches transfers from this date
  Future<List<TransferEvent>> fetchNewErc20Transfers(DateTime fromDate) async {
    try {
      final List<TransferEvent> tx = [];

      final url =
          '/logs/transfers/${_contractToken.addr}/${_account.hex}/new?limit=10&fromDate=${Uri.encodeComponent(fromDate.toUtc().toIso8601String())}';

      final response = await _indexer.get(url: url, headers: {
        'Authorization': 'Bearer ${dotenv.get('INDEXER_KEY')}',
      });

      // convert response array into TransferEvent list
      for (final item in response['array']) {
        tx.add(TransferEvent.fromJson(item));
      }

      return tx;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return <TransferEvent>[];
  }

  /// Transactions

  /// construct erc20 transfer call data
  Uint8List erc20TransferCallData(
    String to,
    BigInt amount,
  ) {
    return _contractToken.transferCallData(
      to,
      EtherAmount.fromBigInt(EtherUnit.kwei, amount).getInWei,
      // EtherAmount.fromBigInt(EtherUnit.finney, amount).getInWei,
    );
  }

  /// Account Abstraction

  // get account address
  Future<EthereumAddress> getAccountAddress(String addr) async {
    return _contractAccountFactory.getAddress(addr);
  }

  /// submit a user op
  Future<(String?, Exception?)> _submitUserOp(
    UserOp userop,
    String eaddr,
  ) async {
    final body = SUJSONRPCRequest(
      method: 'eth_sendUserOperation',
      params: [userop.toJson(), eaddr],
    );

    try {
      final response = await _requestBundler(body);

      return (response.result as String, null);
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      final strerr = exception.toString();

      if (strerr.contains(gasFeeErrorMessage)) {
        return (null, NetworkCongestedException());
      }

      if (strerr.contains(invalidBalanceErrorMessage)) {
        return (null, NetworkInvalidBalanceException());
      }
    }

    return (null, NetworkUnknownException());
  }

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestPaymaster(SUJSONRPCRequest body) async {
    final rawRespoonse = await _paymasterRPC.post(
      body: body,
      headers: erc4337Headers,
    );

    final response = SUJSONRPCResponse.fromJson(rawRespoonse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestBundler(SUJSONRPCRequest body) async {
    final rawRespoonse = await _bundlerRPC.post(
      body: body,
      headers: erc4337Headers,
    );

    final response = SUJSONRPCResponse.fromJson(rawRespoonse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// return paymaster data for constructing a user op
  Future<(PaymasterData?, Exception?)> _getPaymasterData(
    UserOp userop,
    String eaddr,
    String ptype,
  ) async {
    final body = SUJSONRPCRequest(
      method: 'pm_sponsorUserOperation',
      params: [
        userop.toJson(),
        eaddr,
        {'type': ptype},
      ],
    );

    try {
      final response = await _requestPaymaster(body);

      return (PaymasterData.fromJson(response.result), null);
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      final strerr = exception.toString();

      if (strerr.contains(gasFeeErrorMessage)) {
        return (null, NetworkCongestedException());
      }

      if (strerr.contains(invalidBalanceErrorMessage)) {
        return (null, NetworkInvalidBalanceException());
      }
    }

    return (null, NetworkUnknownException());
  }

  /// prepare a userop for with calldata
  Future<(String, UserOp)> prepareUserop(Uint8List calldata) async {
    try {
      // instantiate user op with default values
      final userop = UserOp.defaultUserOp();

      // use the account hex as the sender
      userop.sender = _account.hex;

      // determine the appropriate nonce
      final nonce = await _contractEntryPoint.getNonce(_account.hex);
      userop.nonce = nonce;

      // if it's the first user op from this account, we need to deploy the account contract
      if (nonce == BigInt.zero) {
        // construct the init code to deploy the account
        userop.initCode = _contractAccountFactory.createAccountInitCode(
          credentials.address.hex,
          BigInt.zero,
        );
      }

      // set the appropriate call data for the transfer
      // we need to call account.execute which will call token.transfer
      userop.callData = _contractAccount.executeCallData(
        _contractToken.addr,
        BigInt.zero,
        calldata,
      );

      // set the appropriate gas fees based on network
      final fees = await _ethClient.getGasInEIP1559();
      if (fees.isEmpty) {
        throw Exception('unable to estimate fees');
      }

      final fee = fees.first;

      // ensure we avoid errors by increasing the gas fees
      final manualFeeIncrease = BigInt.from(1);

      userop.maxPriorityFeePerGas =
          fee.maxPriorityFeePerGas * manualFeeIncrease;
      userop.maxFeePerGas = fee.maxFeePerGas * manualFeeIncrease;

      // submit the user op to the paymaster in order to receive information to complete the user op
      final (paymasterData, paymasterErr) = await _getPaymasterData(
        userop,
        _contractEntryPoint.addr,
        _paymasterType,
      );

      if (paymasterErr != null) {
        throw paymasterErr;
      }

      if (paymasterData == null) {
        throw Exception('unable to get paymaster data');
      }

      // add the received data to the user op
      userop.paymasterAndData = paymasterData.paymasterAndData;
      userop.preVerificationGas = paymasterData.preVerificationGas;
      userop.verificationGasLimit = paymasterData.verificationGasLimit;
      userop.callGasLimit = paymasterData.callGasLimit;

      // get the hash of the user op
      final hash = userop.getHash(_contractEntryPoint.addr, chainId.toString());

      // now we can sign the user op
      userop.generateSignature(credentials, hash);

      return (bytesToHex(hash, include0x: true), userop);
    } catch (e) {
      rethrow;
    }
  }

  /// submit a user op
  Future<bool> submitUserop(UserOp userop) async {
    try {
      // send the user op
      final (result, useropErr) =
          await _submitUserOp(userop, _contractEntryPoint.addr);
      if (useropErr != null) {
        throw useropErr;
      }

      return result != null;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  /// Optimistic Transactions

  /// add new erc20 transfer events that are sending
  ///
  /// [tx] the transfer event to add
  Future<TransferEvent?> addSendingLog(TransferEvent tx) async {
    try {
      final url = '/logs/transfers/${_contractToken.addr}/${_account.hex}';

      final encoded = jsonEncode(
        tx.toJson(),
      );

      final body = SignedRequest(convertStringToUint8List(encoded));

      final sig =
          await compute(generateSignature, (encoded, credentials.privateKey));

      final response = await _indexer.post(
        url: url,
        headers: {
          'Authorization': 'Bearer ${dotenv.get('INDEXER_KEY')}',
          'X-Signature': sig,
          'X-Address': credentials.address.hex,
        },
        body: body.toJson(),
      );

      return TransferEvent.fromJson(response['object']);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  /// set status of existing erc20 transfer event that are not success
  ///
  /// [status] number of seconds to go back, uses block time to calculate
  Future<bool> setStatusLog(String hash, TransactionState status) async {
    try {
      final url =
          '/logs/transfers/${_contractToken.addr}/${_account.hex}/$hash';

      final encoded = jsonEncode(
        StatusUpdateRequest(status).toJson(),
      );

      final body = SignedRequest(convertStringToUint8List(encoded));

      final sig =
          await compute(generateSignature, (encoded, credentials.privateKey));

      await _indexer.patch(
        url: url,
        headers: {
          'Authorization': 'Bearer ${dotenv.get('INDEXER_KEY')}',
          'X-Signature': sig,
          'X-Address': credentials.address.hex,
        },
        body: body.toJson(),
      );

      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return false;
  }

  /// dispose of resources
  void dispose() {
    _ethClient.dispose();
  }
}
