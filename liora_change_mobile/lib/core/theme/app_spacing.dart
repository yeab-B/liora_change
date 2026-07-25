/// Spacing and shape scale from `docs/mvp/mobile-issues/00-design-system.md` §3.
///
/// Padding and gaps must come from this scale — arbitrary values are a design
/// system violation.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Horizontal padding for screen-level content.
  static const double screenHorizontal = 20;

  /// Smallest allowed tap target, per the accessibility rules in §3.
  static const double minTapTarget = 48;
}

/// Corner radii from `docs/mvp/mobile-issues/00-design-system.md` §3.
abstract final class AppRadius {
  static const double card = 20;
  static const double button = 14;
  static const double pill = 999;
}

/// Content width cap so cards do not stretch edge-to-edge on tablets (§6).
abstract final class AppLayout {
  static const double maxContentWidth = 600;
}
