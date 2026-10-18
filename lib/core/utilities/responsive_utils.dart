import 'package:flutter/material.dart';

/// Responsive helper for adapting UI across Phone, Tablet, and iPad.
///
/// Usage:
/// ```dart
/// final responsive = ResponsiveUtils(context);
/// final columns = responsive.gridColumns(2); // phone=2, tablet=3, ipad=4
/// final padding = responsive.pagePadding;     // phone=16, tablet=24, ipad=32
/// ```
class ResponsiveUtils {
  final BuildContext context;
  late final double _shortestSide;

  ResponsiveUtils(this.context) {
    final mq = MediaQuery.of(context);
    _shortestSide = mq.size.shortestSide;
  }

  // ─── Device classification ───

  /// true on phones (<600px shortest side)
  bool get isPhone => _shortestSide < 600;

  /// true on tablets (600-900px shortest side)
  bool get isTablet => _shortestSide >= 600 && _shortestSide < 900;

  /// true on large tablets / iPad (>900px shortest side)
  bool get isIpad => _shortestSide >= 900;

  /// true on any tablet or iPad
  bool get isTabletOrIpad => _shortestSide >= 600;

  // ─── Responsive values ───

  /// Grid columns: phone=2, tablet=3, ipad=4
  int gridColumns(int base) {
    if (isIpad) return (base + 2).clamp(2, 6);
    if (isTablet) return (base + 1).clamp(2, 5);
    return base;
  }

  /// Page horizontal padding
  double get pagePadding => isIpad ? 32 : (isTablet ? 24 : 16);

  /// Card border radius
  double get cardRadius => isIpad ? 20 : (isTablet ? 18 : 16);

  /// Bottom nav bar height
  double get navBarHeight => isIpad ? 80 : (isTablet ? 76 : 72);

  /// FAB size
  double get fabSize => isIpad ? 72 : (isTablet ? 68 : 64);

  /// FAB icon size
  double get fabIconSize => isIpad ? 38 : (isTablet ? 36 : 34);

  /// Section header font size
  double get sectionHeaderSize => isIpad ? 18 : (isTablet ? 16 : 15);

  /// Content max width (for centering on tablets/iPad)
  double get maxContentWidth {
    if (isIpad) return 720;
    if (isTablet) return 600;
    return double.infinity;
  }

  /// Quick Add sheet: max width constraint for tablets/iPad
  double get quickAddMaxWidth {
    if (isIpad) return 480;
    if (isTablet) return 420;
    return double.infinity;
  }

  /// Constrain a widget to max content width (useful on tablets)
  Widget constrainWidth(Widget child) {
    if (maxContentWidth == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}
