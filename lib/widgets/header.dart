import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class Header extends StatefulWidget {
  final String title;
  final String? subTitle;
  final Widget? subTitleWidget;
  final Widget? actionButton;
  final bool showBackButton;
  final bool transparent;

  const Header({
    super.key,
    required this.title,
    this.subTitleWidget,
    this.subTitle,
    this.actionButton,
    this.showBackButton = false,
    this.transparent = false,
  });

  @override
  HeaderState createState() => HeaderState();
}

class HeaderState extends State<Header> {
  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 60,
      ),
      decoration: BoxDecoration(
        color: widget.transparent
            ? ThemeColors.transparent.resolveFrom(context)
            : ThemeColors.uiBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(color: ThemeColors.border.resolveFrom(context)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.showBackButton)
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleDismiss(context),
                  child: const Icon(
                    CupertinoIcons.back,
                  ),
                ),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.actionButton != null)
                Container(
                  height: 60.0,
                  constraints: const BoxConstraints(
                    minWidth: 60,
                  ),
                  child: Center(
                    child: widget.actionButton,
                  ),
                ),
            ],
          ),
          if (widget.subTitleWidget != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                child: widget.subTitleWidget,
              ),
            ),
          if (widget.subTitle != null && widget.subTitle!.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                child: Text(
                  widget.subTitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
