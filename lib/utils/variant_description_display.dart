/// Whether to show a variant description line (non-redundant, non-empty).
bool shouldShowVariantDescription(String variantName, String? description) {
  if (description == null) return false;
  final trimmed = description.trim();
  if (trimmed.isEmpty) return false;
  return trimmed.toLowerCase() != variantName.trim().toLowerCase();
}
