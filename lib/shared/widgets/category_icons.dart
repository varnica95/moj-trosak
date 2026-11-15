import 'package:flutter/material.dart';

/// Pretvara ključ ikone iz baze u Material ikonu.
///
/// U bazi se čuva ključ (a ne codepoint) kako bi tree-shaking ikona radio
/// i kako bi se ikone mogle mijenjati bez migracije podataka.
IconData categoryIcon(String? key) => switch (key) {
  'bolt' => Icons.bolt,
  'flame' => Icons.local_fire_department_outlined,
  'water' => Icons.water_drop_outlined,
  'building' => Icons.apartment_outlined,
  'wifi' => Icons.wifi,
  'recycling' => Icons.recycling,
  'receipt' => Icons.receipt_long_outlined,
  'cart' => Icons.shopping_cart_outlined,
  'spa' => Icons.spa_outlined,
  'clothing' => Icons.checkroom_outlined,
  'devices' => Icons.devices_other_outlined,
  'home' => Icons.home_outlined,
  'food' => Icons.restaurant_outlined,
  'drink' => Icons.local_drink_outlined,
  _ => Icons.category_outlined,
};

/// Boja kategorije ili zadana boja ako kategorija nije postavljena.
Color categoryColor(int? argb, BuildContext context) =>
    argb != null ? Color(argb) : Theme.of(context).colorScheme.primary;
