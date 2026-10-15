import 'package:flutter/cupertino.dart';

abstract final class BuleSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class BuleRadius {
  static const double header = 8;
  static const double card = 14;
}

abstract final class BuleTextStyles {
  static const pageTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.4,
  );

  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );

  static const body = TextStyle(fontSize: 16, height: 1.35);
  static const supporting = TextStyle(fontSize: 14, height: 1.35);
  static const eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );
}

class BuleWideFrame extends StatelessWidget {
  const BuleWideFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final margin = constraints.maxWidth >= 1000
          ? BuleSpacing.xxl
          : BuleSpacing.xl;
      return ColoredBox(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              margin: EdgeInsets.all(margin),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(BuleRadius.card),
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

bool useWideLayout(BuildContext context, BoxConstraints constraints) {
  final media = MediaQuery.sizeOf(context);
  return constraints.maxWidth >= 700 && media.shortestSide >= 600;
}
