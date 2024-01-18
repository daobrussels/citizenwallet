import 'dart:typed_data';

import 'package:citizenwallet/utils/currency.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pointycastle/digests/keccak.dart';
import 'package:web3dart/crypto.dart';

const String pendingTransactionId = 'TEMP_HASH';

Map<TransactionAuthor, List<String>> createKnownAuthorsMap() => {
      TransactionAuthor.bank: [
        dotenv.get('KNOWN_ADDRESS_BANK').toLowerCase(),
      ],
      TransactionAuthor.bar: [],
    };

TransactionAuthor getTransactionAuthor(String own, String from, String to) {
  final knownAuthors = createKnownAuthorsMap();

  // is it the bank?
  if (!knownAuthors[TransactionAuthor.bank]!.contains(own.toLowerCase()) &&
      (knownAuthors[TransactionAuthor.bank]!.contains(from) ||
          knownAuthors[TransactionAuthor.bank]!.contains(to))) {
    return TransactionAuthor.bank;
  }

  // is it the bar?
  if (!knownAuthors[TransactionAuthor.bar]!.contains(own.toLowerCase()) &&
      (knownAuthors[TransactionAuthor.bar]!.contains(from) ||
          knownAuthors[TransactionAuthor.bar]!.contains(to))) {
    return TransactionAuthor.bar;
  }

  return TransactionAuthor.unknown;
}

enum TransactionState {
  sending,
  pending,
  success,
  fail,
}

enum TransactionAuthor {
  self('assets/icons/profile.svg', 'You'),
  unknown('assets/icons/profile.svg', 'Unknown'),
  known('assets/icons/profile.svg', 'Known'),
  bar('assets/icons/bar_icon.svg', 'Bar'),
  bank('assets/icons/citizenbank.svg', 'Bank');

  const TransactionAuthor(this.icon, this.name);

  final String icon;
  final String name;
}

class CWTransaction {
  final String id;
  final String hash;
  final int chainId;
  final String from;
  final String to;
  final String description;
  String _amount = '0.0';
  DateTime date = DateTime.now();
  final int blockNumber;

  String error = '';
  TransactionState state = TransactionState.success;

  CWTransaction(
    this._amount, {
    required this.id,
    required this.hash,
    this.chainId = 0,
    this.from = '0x',
    this.to = '0x',
    required this.description,
    required this.date,
    this.blockNumber = 0,
    this.state = TransactionState.success,
  });
  CWTransaction.empty({
    this.id = 'empty',
    this.hash = '0x',
    this.chainId = 0,
    this.from = '0x',
    this.to = '0x',
    this.description = '',
    this.blockNumber = 0,
    this.state = TransactionState.success,
  });
  CWTransaction.sending(
    this._amount, {
    required this.id,
    required this.hash,
    this.chainId = 0,
    this.from = '0x',
    this.to = '0x',
    required this.description,
    required this.date,
    this.blockNumber = 0,
    this.state = TransactionState.sending,
  });
  CWTransaction.pending(
    this._amount, {
    required this.id,
    required this.hash,
    this.chainId = 0,
    this.from = '0x',
    this.to = '0x',
    required this.description,
    required this.date,
    this.blockNumber = 0,
    this.state = TransactionState.pending,
  });
  CWTransaction.failed(
    this._amount, {
    required this.id,
    required this.hash,
    this.chainId = 0,
    this.from = '0x',
    this.to = '0x',
    required this.description,
    required this.date,
    this.blockNumber = 0,
    this.state = TransactionState.fail,
    this.error = '',
  });

  // copy with
  CWTransaction copyWith({
    String? id,
    String? hash,
    int? chainId,
    String? from,
    String? to,
    String? title,
    String? amount,
    DateTime? date,
    int? blockNumber,
    TransactionState? state,
  }) {
    return CWTransaction(
      amount ?? _amount,
      id: id ?? this.id,
      hash: hash ?? this.hash,
      chainId: chainId ?? this.chainId,
      from: from ?? this.from,
      to: to ?? this.to,
      description: title ?? this.description,
      date: date ?? this.date,
      blockNumber: blockNumber ?? this.blockNumber,
      state: state ?? this.state,
    );
  }

  String get amount => _amount;

  bool get isSending => state == TransactionState.sending;
  bool get isPending => state == TransactionState.pending;
  bool get isFailed => state == TransactionState.fail;

  bool get isProcessing => isSending || isPending;

  bool get isNotSent => state != TransactionState.sending;

  bool isIncoming(String to) => this.to == to;

  String get formattedAmount => formatAmount(
        double.tryParse(amount) ?? 0.0,
        decimalDigits: 2,
      );

  // String formattedAmount(CWWallet wallet, {bool isIncoming = false}) =>
  //     formatCurrency(
  //       double.tryParse(amount) ?? 0.0,
  //       wallet.symbol,
  //       decimalDigits: wallet.decimalDigits,
  //       isIncoming: isIncoming,
  //     );

  String generateHash(BigInt nonce, BigInt amount) {
    var buf = BytesBuilder();

    // Write each value to the buffer as bytes
    buf.add(_int64ToBytes(chainId));
    buf.add(_int64ToBytes(0));

    final hexNonce = nonce.toRadixString(16);
    buf.add(hexToBytes(hexNonce.padLeft(64, '0')));
    // buf.add(_int64ToBytes(nonce.toInt()));

    buf.add(hexToBytes(from));
    buf.add(hexToBytes(to));

    final hexAmount = amount.toRadixString(16);
    buf.add(hexToBytes(hexAmount.padLeft(64, '0')));

    // Calculate the Keccak256 hash
    var digest = KeccakDigest(256);
    var hash = digest.process(buf.toBytes());

    return bytesToHex(hash, include0x: true);
  }

  // convert to Transaction object from JSON
  CWTransaction.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        hash = json['hash'],
        chainId = json['chainId'],
        from = json['from'],
        to = json['to'],
        description = json['description'],
        _amount = json['amount'],
        date = DateTime.parse(json['date']),
        blockNumber = json['blockNumber'],
        state = json['state'] ?? TransactionState.success;

  // Convert a Transaction object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'id': id,
        'hash': hash,
        'chainId': chainId,
        'from': from,
        'to': to,
        'description': description,
        'amount': _amount,
        'blockNumber': blockNumber,
        'date': date.toIso8601String(),
      };

  void pending() {
    state = TransactionState.pending;
  }

  void success() {
    state = TransactionState.success;
  }
}

Uint8List _int64ToBytes(int value) {
  var bdata = ByteData(8);
  bdata.setInt64(0, value, Endian.big);
  return bdata.buffer.asUint8List();
}
