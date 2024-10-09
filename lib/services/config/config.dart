import 'package:collection/collection.dart';

const String defaultPrimary = '#A256FF';

int parseHexColor(String hex) {
  return int.parse('FF${(hex).substring(1)}', radix: 16);
}

class ColorTheme {
  final int primary;

  ColorTheme({
    primary,
  }) : primary = primary ?? parseHexColor(defaultPrimary);

  factory ColorTheme.fromJson(Map<String, dynamic> json) {
    return ColorTheme(
      primary: parseHexColor(json['primary'] ?? defaultPrimary),
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'primary': '#${primary.toRadixString(16).substring(2)}',
    };
  }
}

class CommunityConfig {
  final String name;
  final String description;
  final String url;
  final String alias;
  final String logo;
  final String? customDomain;
  final bool hidden;
  final ColorTheme theme;

  CommunityConfig({
    required this.name,
    required this.description,
    required this.url,
    required this.alias,
    required this.logo,
    this.customDomain,
    this.hidden = false,
    required this.theme,
  });

  factory CommunityConfig.fromJson(Map<String, dynamic> json) {
    final theme = json['theme'] == null
        ? ColorTheme()
        : ColorTheme.fromJson(json['theme']);

    return CommunityConfig(
      name: json['name'],
      description: json['description'],
      url: json['url'],
      alias: json['alias'],
      logo: json['logo'] ?? '',
      customDomain: json['custom_domain'],
      hidden: json['hidden'] ?? false,
      theme: theme,
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'url': url,
      'alias': alias,
      'logo': logo,
      'custom_domain': customDomain,
      'hidden': hidden,
      'theme': theme,
    };
  }

  // to string
  @override
  String toString() {
    return 'CommunityConfig{name: $name, description: $description, url: $url, alias: $alias}';
  }

  String walletUrl(String deepLinkBaseUrl) =>
      '$deepLinkBaseUrl/#/?alias=$alias';
}

class ScanConfig {
  final String url;
  final String name;

  ScanConfig({
    required this.url,
    required this.name,
  });

  factory ScanConfig.fromJson(Map<String, dynamic> json) {
    return ScanConfig(
      url: json['url'],
      name: json['name'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
    };
  }

  // to string
  @override
  String toString() {
    return 'ScanConfig{url: $url, name: $name}';
  }
}

class IndexerConfig {
  final String url;
  final String ipfsUrl;
  final String key;

  IndexerConfig({
    required this.url,
    required this.ipfsUrl,
    required this.key,
  });

  factory IndexerConfig.fromJson(Map<String, dynamic> json) {
    return IndexerConfig(
      url: json['url'],
      ipfsUrl: json['ipfs_url'],
      key: json['key'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'ipfs_url': ipfsUrl,
      'key': key,
    };
  }

  // to string
  @override
  String toString() {
    return 'IndexerConfig{url: $url, ipfsUrl: $ipfsUrl, key: $key}';
  }
}

class IPFSConfig {
  final String url;

  IPFSConfig({
    required this.url,
  });

  factory IPFSConfig.fromJson(Map<String, dynamic> json) {
    return IPFSConfig(
      url: json['url'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }

  // to string
  @override
  String toString() {
    return 'IPFSConfig{url: $url}';
  }
}

class NodeConfig {
  final int chainId;
  final String url;
  final String wsUrl;

  NodeConfig({
    required this.chainId,
    required this.url,
    required this.wsUrl,
  });

  factory NodeConfig.fromJson(Map<String, dynamic> json) {
    return NodeConfig(
      chainId: json['chain_id'] ?? 1,
      url: json['url'],
      wsUrl: json['ws_url'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'chain_id': chainId,
      'url': url,
      'ws_url': wsUrl,
    };
  }

  // to string
  @override
  String toString() {
    return 'NodeConfig{chainId: $chainId url: $url, wsUrl: $wsUrl}';
  }
}

class ERC4337Config {
  final String entrypointAddress;
  final String? paymasterAddress;
  final String accountFactoryAddress;
  final String paymasterType;
  final String profileAddress;
  final int gasExtraPercentage;

  ERC4337Config({
    required this.entrypointAddress,
    this.paymasterAddress,
    required this.accountFactoryAddress,
    required this.paymasterType,
    required this.profileAddress,
    this.gasExtraPercentage = 13,
  });

  factory ERC4337Config.fromJson(Map<String, dynamic> json) {
    return ERC4337Config(
      entrypointAddress: json['entrypoint_address'],
      paymasterAddress: json['paymaster_address'],
      accountFactoryAddress: json['account_factory_address'],
      paymasterType: json['paymaster_type'],
      profileAddress: json['profile_address'],
      gasExtraPercentage: json['gas_extra_percentage'] ?? 13,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entrypoint_address': entrypointAddress,
      if (paymasterAddress != null) 'paymaster_address': paymasterAddress,
      'account_factory_address': accountFactoryAddress,
      'paymaster_type': paymasterType,
      'profile_address': profileAddress,
      'gas_extra_percentage': gasExtraPercentage,
    };
  }

  // to string
  @override
  String toString() {
    return 'ERC4337Config{entrypointAddress: $entrypointAddress, paymasterAddress: $paymasterAddress, accountFactoryAddress: $accountFactoryAddress, paymasterType: $paymasterType, profileAddress: $profileAddress}';
  }
}

class TokenConfig {
  final String standard;
  final String address;
  final String name;
  final String symbol;
  final int decimals;
  final int chainId;

  TokenConfig({
    required this.standard,
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.chainId,
  });

  factory TokenConfig.fromJson(Map<String, dynamic> json) {
    return TokenConfig(
      standard: json['standard'],
      address: json['address'],
      name: json['name'],
      symbol: json['symbol'],
      decimals: json['decimals'],
      chainId: json['chain_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'standard': standard,
      'address': address,
      'name': name,
      'symbol': symbol,
      'decimals': decimals,
      'chain_id': chainId,
    };
  }

  // to string
  @override
  String toString() {
    return 'TokenConfig{standard: $standard, address: $address , name: $name, symbol: $symbol, decimals: $decimals, chainId: $chainId}';
  }
}

class ProfileConfig {
  final String address;

  ProfileConfig({
    required this.address,
  });

  factory ProfileConfig.fromJson(Map<String, dynamic> json) {
    return ProfileConfig(
      address: json['address'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'address': address,
    };
  }

  // to string
  @override
  String toString() {
    return 'ProfileConfig{address: $address}';
  }
}

enum PluginLaunchMode {
  webview,
  external;
}

class PluginConfig {
  final String name;
  final String icon;
  final String url;
  final PluginLaunchMode launchMode;
  final String? action;

  PluginConfig({
    required this.name,
    required this.icon,
    required this.url,
    this.launchMode = PluginLaunchMode.external,
    this.action,
  });

  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      name: json['name'],
      icon: json['icon'],
      url: json['url'],
      launchMode: json['launch_mode'] == 'webview'
          ? PluginLaunchMode.webview
          : PluginLaunchMode.external,
      action: json['action'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'url': url,
      'launch_mode': launchMode.name,
      if (action != null) 'action': action,
    };
  }

  // to string
  @override
  String toString() {
    return 'PluginConfig{name: $name, icon: $icon, url: $url}';
  }
}

class Legacy4337Bundlers {
  final ERC4337Config polygon;
  final ERC4337Config base;
  final ERC4337Config celo;

  Legacy4337Bundlers({
    required this.polygon,
    required this.base,
    required this.celo,
  });

  factory Legacy4337Bundlers.fromJson(Map<String, dynamic> json) {
    return Legacy4337Bundlers(
      polygon: ERC4337Config.fromJson(json['137']),
      base: ERC4337Config.fromJson(json['8453']),
      celo: ERC4337Config.fromJson(json['42220']),
    );
  }

  ERC4337Config get(String chainId) {
    if (chainId == '137') {
      return polygon;
    }

    return base;
  }

  ERC4337Config? getFromAlias(String alias) {
    if (alias.contains('celo')) {
      return null;
    }

    return switch (alias) {
      'usdc.base' => base,
      'wallet.oak.community' => base,
      'ceur.celo' => celo,
      _ => polygon
    };
  }
}

class CardsConfig {
  final String cardFactoryAddress;

  CardsConfig({
    required this.cardFactoryAddress,
  });

  factory CardsConfig.fromJson(Map<String, dynamic> json) {
    return CardsConfig(
      cardFactoryAddress: json['card_factory_address'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'card_factory_address': cardFactoryAddress,
    };
  }

  // to string
  @override
  String toString() {
    return 'CardsConfig{card_factory_address: $cardFactoryAddress}';
  }
}

class SafeCardsConfig {
  final String cardManagerAddress;
  final String instanceId;

  SafeCardsConfig({
    required this.cardManagerAddress,
    required this.instanceId,
  });

  factory SafeCardsConfig.fromJson(Map<String, dynamic> json) {
    return SafeCardsConfig(
      cardManagerAddress: json['card_manager_address'],
      instanceId: json['instance_id'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'card_manager_address': cardManagerAddress,
    };
  }

  // to string
  @override
  String toString() {
    return 'SafeCardsConfig{card_manager_address: $cardManagerAddress}';
  }
}

class ChainConfig {
  final NodeConfig node;
  final ERC4337Config account;
  final CardsConfig? cards;
  final SafeCardsConfig? safeCards;

  ChainConfig({
    required this.node,
    required this.account,
    this.cards,
    this.safeCards,
  });

  factory ChainConfig.fromJson(Map<String, dynamic> json) {
    return ChainConfig(
      node: NodeConfig.fromJson(json['node']),
      account: ERC4337Config.fromJson(json['account']),
      cards: json['cards'] != null ? CardsConfig.fromJson(json['cards']) : null,
      safeCards: json['safe_cards'] != null
          ? SafeCardsConfig.fromJson(json['safe_cards'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node': node.toJson(),
      'account': account.toJson(),
      if (cards != null) 'cards': cards!.toJson(),
      if (safeCards != null) 'safe_cards': safeCards!.toJson(),
    };
  }
}

class Config {
  final CommunityConfig community;
  final List<TokenConfig> tokens;
  final ScanConfig scan;
  final Map<String, ChainConfig> chains;
  final IPFSConfig ipfs;
  final List<PluginConfig> plugins;
  final int version;
  bool online;

  Config({
    required this.community,
    required this.tokens,
    required this.scan,
    required this.chains,
    required this.ipfs,
    required this.plugins,
    this.version = 0,
    this.online = true,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      community: CommunityConfig.fromJson(json['community']),
      tokens:
          (json['tokens'] as List).map((e) => TokenConfig.fromJson(e)).toList(),
      scan: ScanConfig.fromJson(json['scan']),
      chains: (json['chains'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, ChainConfig.fromJson(value)),
      ),
      ipfs: IPFSConfig.fromJson(json['ipfs']),
      plugins: (json['plugins'] as List)
          .map((e) => PluginConfig.fromJson(e))
          .toList(),
      version: json['version'] ?? 0,
      online: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community': community.toJson(),
      'tokens': tokens.map((e) => e.toJson()).toList(),
      'scan': scan.toJson(),
      'chains': chains.map((key, value) => MapEntry(key, value.toJson())),
      'ipfs': ipfs.toJson(),
      'plugins': plugins.map((e) => e.toJson()).toList(),
      'version': version,
    };
  }

  // to string
  @override
  String toString() {
    return 'Config{community: $community, scan: $scan, chains: $chains, ipfs: $ipfs, tokens: $tokens, plugins: $plugins}';
  }

  bool hasCards() {
    return chains.values.any((chain) => chain.cards != null);
  }

  PluginConfig? getTopUpPlugin() {
    return plugins.firstWhereOrNull((plugin) => plugin.action == 'topup');
  }
}
