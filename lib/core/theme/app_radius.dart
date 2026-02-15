import 'package:flutter/material.dart';

abstract final class AppRadius {
  // ── Raw values ──
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const card = 28.0;
  static const sheet = 40.0;
  static const pill = 100.0;

  // ── BorderRadius presets ──
  static final borderRadiusSm = BorderRadius.circular(sm);
  static final borderRadiusMd = BorderRadius.circular(md);
  static final borderRadiusLg = BorderRadius.circular(lg);
  static final borderRadiusXl = BorderRadius.circular(xl);
  static final borderRadiusXxl = BorderRadius.circular(xxl);
  static final borderRadiusCard = BorderRadius.circular(card);
  static final borderRadiusPill = BorderRadius.circular(pill);
  static final borderRadiusSheet = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
}
