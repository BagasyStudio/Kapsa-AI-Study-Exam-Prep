/// Remove numeric prefixes, underscores, and format noise from raw titles.
///
/// This is a UI-cleaning utility, NOT semantic/localization. It does not
/// infer missing accents or rewrite content meaningfully.
///
/// Examples:
///   "59_Biologia_Celular" → "Biologia Celular"
///   "3 math_review"       → "Math Review"
///   "History"             → "History"
String cleanDisplayTitle(String raw) {
  // Strip leading numeric prefix like "59_" or "59 "
  final stripped = raw.replaceFirst(RegExp(r'^\d+[_\s]*'), '');
  // Replace remaining underscores with spaces
  final spaced = stripped.replaceAll('_', ' ');
  // Title-case each word
  return spaced
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
