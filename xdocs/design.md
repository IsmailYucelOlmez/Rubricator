# 🎨 Rubricator Design System (FULL – Theme + Typography + UI Rules)

## 🎯 Goal

Implement a complete design system for the Rubricator app that reflects:

* Editorial / book-focused identity
* Minimal modern UI
* Strong visual hierarchy
* Dark theme as primary

This system must be reusable, scalable, and consistent across all features.

---

# 🧱 Architecture

Create centralized design system:

```id="design_structure"
lib/
 ├── core/theme/
 │    ├── app_colors.dart
 │    ├── app_typography.dart
 │    ├── app_theme.dart
 │    ├── app_spacing.dart
 │    ├── app_radius.dart
 │
 ├── core/widgets/
 │    ├── app_button.dart
 │    ├── app_card.dart
 │    ├── app_text.dart
 │    ├── app_input.dart
```

---

# 🎨 COLORS

## Primary (Brand)

```dart id="colors_primary"
class AppColors {
  static const primary = Color(0xFF8B1E2D); // Deep Red
}
```

---

## Dark Theme (DEFAULT)

```dart id="colors_dark"
static const background = Color(0xFF0F0F10);
static const surface = Color(0xFF1A1A1C);
static const card = Color(0xFF222225);
```

---

## Text Colors

```dart id="colors_text"
static const textPrimary = Color(0xFFFFFFFF);
static const textSecondary = Color(0xFFB0B0B0);
```

---

## Accent

```dart id="colors_accent"
static const gold = Color(0xFFC2A878);
```

---

# 🔤 TYPOGRAPHY

## Fonts

* Headline: Efco Brookshire
* Body: Donau

---

## Implementation

```dart id="typography"
class AppTypography {
  static const heading = TextStyle(
    fontFamily: 'EfcoBrookshire',
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const body = TextStyle(
    fontFamily: 'Donau',
    fontSize: 14,
  );
}
```

---

## Hierarchy

* H1 → Efco Brookshire
* H2 → Donau (semi-bold)
* Body → Donau
* Caption → Donau (light)

---

# 📐 SPACING SYSTEM

```dart id="spacing"
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
```

---

# 🔲 RADIUS SYSTEM

```dart id="radius"
class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
}
```

---

# 🎯 THEME CONFIGURATION

```dart id="theme"
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primary,
  fontFamily: 'Donau',

  cardColor: AppColors.card,

  textTheme: TextTheme(
    bodyMedium: AppTypography.body,
  ),
);
```

---

# 🧩 COMPONENT SYSTEM

---

## 🔘 Button

```dart id="button"
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AppButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
```

---

## 🧾 Card

```dart id="card"
class AppCard extends StatelessWidget {
  final Widget child;

  const AppCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}
```

---

## 📝 Input

```dart id="input"
class AppInput extends StatelessWidget {
  final TextEditingController controller;

  const AppInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
```

---

# 📱 UI RULES (STRICT)

---

## 1. Cover-first design

* book covers must dominate UI
* text is secondary

---

## 2. Minimal color usage

* primary red ONLY for actions
* avoid multiple accent colors

---

## 3. Spacing consistency

* always use AppSpacing
* never hardcode values

---

## 4. Typography consistency

* NEVER use default fonts
* always use AppTypography

---

## 5. Dark theme priority

* design everything for dark first
* light theme optional

---

# ⚡ UX RULES

* fast perception
* low visual noise
* high readability

---

# 🚫 ANTI-PATTERNS

* ❌ no random colors
* ❌ no inline styles
* ❌ no inconsistent spacing
* ❌ no large shadows

---

# 🎯 EXPECTED OUTPUT

App must:

* feel consistent across all pages
* highlight book covers
* reflect editorial style
* maintain strong branding

---

# 🔥 FINAL RULE

Design must feel like:

👉 a premium reading platform
NOT a generic mobile app
