/// Spacing constants matching Tailwind's 4px base scale.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4.0;   // gap-1
  static const double sm = 8.0;   // gap-2
  static const double md = 12.0;  // gap-3
  static const double lg = 16.0;  // gap-4
  static const double xl = 20.0;  // gap-5
  static const double xxl = 24.0; // gap-6
  static const double xxxl = 32.0;// gap-8
  static const double huge = 48.0;// gap-12

  // Page padding
  static const double pagePadding = 20.0;
  static const double pageTopPadding = 24.0;

  // Card padding
  static const double cardPadding = 24.0;   // p-6
  static const double cardPaddingSm = 16.0; // p-4
  static const double cardPaddingLg = 32.0; // p-8
}

/// Border radius constants.
class AppRadius {
  const AppRadius._();

  static const double none = 0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 18.0;    // rounded-[18px]
  static const double xl = 24.0;    // rounded-3xl
  static const double xxl = 32.0;   // rounded-[2rem]
  static const double full = 9999.0; // rounded-full
}
