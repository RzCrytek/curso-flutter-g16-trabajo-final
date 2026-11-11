const _gmailDomains = ["gmail.com", "googlemail.com"];
final _emailPattern = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");

bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

String normalizeEmail(String email) {
  final parts = email.trim().toLowerCase().split("@");
  final localPart = parts.isNotEmpty ? parts[0] : "";
  final domain = parts.length > 1 ? parts[1] : "";

  if (!_gmailDomains.contains(domain)) return "$localPart@$domain";
  return "${localPart.split('+')[0].replaceAll('.', '')}@gmail.com";
}

({List<String> valid, List<String> invalid}) parseEmails(String text) {
  final tokens = text
      .split(RegExp(r"[\s,;]+"))
      .where((token) => token.isNotEmpty);
  return (
    valid: tokens.where((token) => _emailPattern.hasMatch(token)).toList(),
    invalid: tokens.where((token) => !_emailPattern.hasMatch(token)).toList(),
  );
}
