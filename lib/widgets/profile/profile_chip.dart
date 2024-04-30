import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileChip extends StatelessWidget {
  final ProfileV1? selectedProfile;
  final String? selectedAddress;
  final void Function()? handleDeSelect;

  const ProfileChip({
    super.key,
    this.selectedProfile,
    this.selectedAddress,
    this.handleDeSelect,
  });

  @override
  Widget build(BuildContext context) {
    //   return Container(
    //     height: 60,
    //     decoration: BoxDecoration(
    //       color: ThemeColors.surfaceBackgroundSubtle.resolveFrom(context),
    //       borderRadius: const BorderRadius.all(
    //         Radius.circular(30),
    //       ),
    //     ),
    //     padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
    //     child: Row(
    //       mainAxisAlignment: MainAxisAlignment.start,
    //       crossAxisAlignment: CrossAxisAlignment.center,
    //       children: [
    //         ProfileCircle(
    //           size: 40,
    //           imageUrl: selectedProfile?.imageSmall,
    //         ),
    //         const SizedBox(width: 10),
    //         Expanded(
    //           child: Column(
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               Text(
    //                 selectedProfile != null && selectedProfile!.name.isNotEmpty
    //                     ? selectedProfile?.name ??
    //                         AppLocalizations.of(context)!.anonymous
    //                     : AppLocalizations.of(context)!.anonymous,
    //                 style: TextStyle(
    //                   color: ThemeColors.surfaceText.resolveFrom(context),
    //                   fontWeight: FontWeight.bold,
    //                 ),
    //                 maxLines: 1,
    //                 overflow: TextOverflow.ellipsis,
    //               ),
    //               const SizedBox(width: 10),
    //               Text(
    //                 selectedAddress ??
    //                     (selectedProfile != null
    //                         ? '@${selectedProfile!.username}'
    //                         : ''),
    //                 style: TextStyle(
    //                   color: ThemeColors.surfaceText.resolveFrom(context),
    //                 ),
    //                 maxLines: 1,
    //                 overflow: TextOverflow.ellipsis,
    //               ),
    //             ],
    //           ),
    //         ),
    //         if (handleDeSelect != null)
    //           CupertinoButton(
    //             padding: const EdgeInsets.all(0),
    //             onPressed: handleDeSelect,
    //             child: Icon(
    //               CupertinoIcons.xmark_circle_fill,
    //               color: ThemeColors.surfaceSubtle.resolveFrom(context),
    //             ),
    //           ),
    //       ],
    //     ),
    //   );
    // }
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: ThemeColors.background.resolveFrom(context),
        borderRadius: const BorderRadius.all(
          Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileCircle(
            size: 40,
            imageUrl: selectedProfile?.imageSmall,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                selectedProfile != null && selectedProfile!.name.isNotEmpty
                    ? selectedProfile?.name ??
                        AppLocalizations.of(context)!.anonymous
                    : AppLocalizations.of(context)!.anonymous,
                style: TextStyle(
                  color: ThemeColors.black.resolveFrom(context),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(
                  height: 5), // Adding some spacing between name and username
              // Text(
              //   selectedAddress ??
              //       (selectedProfile != null
              //           ? '@${selectedProfile!.username}'
              //           : ''),
              //   style: TextStyle(
              //     color: ThemeColors.surfaceText.resolveFrom(context),
              //   ),
              //   maxLines: 1,
              //   overflow: TextOverflow.ellipsis,
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
