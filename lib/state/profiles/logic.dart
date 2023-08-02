import 'package:citizenwallet/services/db/contacts.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:citizenwallet/services/cache/contacts.dart';

class ProfilesLogic extends WidgetsBindingObserver {
  late ProfilesState _state;
  final WalletService _wallet = WalletService();

  late Debounce debouncedSearchProfile;

  late Debounce debouncedLoad;
  List<String> toLoad = [];
  bool stopLoading = false;

  ProfilesLogic(BuildContext context) {
    _state = context.read<ProfilesState>();

    debouncedLoad = debounce(
      _loadProfile,
      const Duration(milliseconds: 500),
    );

    debouncedSearchProfile = debounce(
      (String username) {
        _searchProfile(username);
      },
      const Duration(milliseconds: 500),
    );
  }

  Future<ProfileV1?> _loadCachedProfile(String addr) async {
    try {
      final cachedProfile = await ContactsCache().get(addr, () async {
        final fetchedProfile = await _wallet.getProfile(addr);
        if (fetchedProfile == null) {
          return null;
        }

        return DBContact(
          account: fetchedProfile.account,
          username: fetchedProfile.username,
          name: fetchedProfile.name,
          description: fetchedProfile.description,
          image: fetchedProfile.image,
          imageMedium: fetchedProfile.imageMedium,
          imageSmall: fetchedProfile.imageSmall,
        );
      });

      if (cachedProfile != null) {
        final profile = ProfileV1.fromMap(cachedProfile.toMap());

        return profile;
      }
    } catch (exception) {
      //
    }

    return null;
  }

  _loadProfile() async {
    if (stopLoading) {
      return;
    }

    final toLoadCopy = [...toLoad];
    toLoad = [];

    for (final addr in toLoadCopy) {
      if (stopLoading) {
        return;
      }
      try {
        final profile = await _loadCachedProfile(addr);

        if (profile != null) {
          _state.isLoading(addr);

          await delay(const Duration(milliseconds: 250));

          _state.isLoaded(addr, profile);
          continue;
        }
      } catch (exception) {
        //
      }

      await delay(const Duration(milliseconds: 125));
      _state.isError(addr);
    }
  }

  Future<void> loadProfile(String addr) async {
    try {
      if (!toLoad.contains(addr) && !_state.exists(addr)) {
        toLoad.add(addr);
        debouncedLoad();
      }
    } catch (exception) {
      //
    }
  }

  Future<void> _searchProfile(String value) async {
    try {
      final cleanValue = value.replaceFirst('@', '');

      _state.isSearching(cleanValue);

      final localUsername = _state.getLocalUsername(cleanValue);
      if (localUsername != null) {
        // no need to fetch if it is already stored locally
        await delay(const Duration(milliseconds: 500));
        _state.isSearchingSuccess(localUsername);
        return;
      }

      final profile = cleanValue.startsWith('0x')
          ? await _wallet.getProfile(cleanValue)
          : await _wallet.getProfileByUsername(cleanValue);
      if (profile == null) {
        throw Exception('Profile not found');
      }

      _state.isSearchingSuccess(profile);
      return;
    } catch (e) {
      //
    }

    _state.isSearchingError();
  }

  Future<ProfileV1?> getProfile(String addr) async {
    try {
      _state.isSearching(null);

      final profile = await _loadCachedProfile(addr);

      if (profile != null) {
        _state.isSearchingSuccess(profile);
        _state.isSelected(null);
        return profile;
      }
    } catch (exception) {
      //
    }

    _state.isSearchingError();
    return null;
  }

  Future<void> searchProfile(String username) async {
    _state.isSearching(null);
    debouncedSearchProfile([username]);
  }

  void selectProfile(ProfileV1? profile) {
    _state.isSelected(profile);
  }

  void deSelectProfile() {
    _state.isDeSelected();
  }

  void clearSearch() {
    _state.clearSearch();
  }

  void pause() {
    debouncedLoad.cancel();
    stopLoading = true;
  }

  void resume() {
    stopLoading = false;
    debouncedLoad();
  }

  void dispose() {
    _state.clearSearch(notify: false);
    debouncedSearchProfile.cancel();
    pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        pause();
        break;
      default:
        resume();
    }
  }
}
