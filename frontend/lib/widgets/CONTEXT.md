# Overview
This directory contains reusable, presentational UI components for the Mindful Flutter app. These widgets enforce a consistent design language (primarily "Liquid Glass" and modern iOS-style transitions) across all screens.

# Primary Files & Responsibilities

* **`glass_container.dart`**: The core component for the "Liquid Glass" design aesthetic. It implements `BackdropFilter` with `ImageFilter.blur` to create semi-transparent, frosted-glass effects used extensively in dashboards, cards, and bottom sheets.
* **`custom_text_field.dart`**: A standardized text input field with unified styling, error handling, and focus states. Used in authentication, profile editing, and text-based chat input.
* **`page_transitions.dart`**: Custom route transition classes. Uses `PageRouteBuilder` and `SlideTransition`/`FadeTransition` combinations to create smooth, native-feeling navigations between screens.
* **`logo_text.dart`**: A reusable, stylized typography widget specifically for rendering the "Mindful" brand name or key headers with specific font weights (e.g., using `GoogleFonts.outfit`).

# Key Logic Flow & Edge Cases

1. **Performance over aesthetics:** Since `BackdropFilter` (`glass_container.dart`) can be performance-heavy on older Android devices, these widgets are built with internal boundary limits and simple gradients to minimize GPU overdraw.
2. **Reusability:** Widgets here must remain "dumb" (stateless or visually-isolated stateful). They should not import business logic from `lib/services/` directly; instead, they receive callbacks (`VoidCallback`, `Function(String)`) from their parent `screens`.
