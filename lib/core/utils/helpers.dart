class Helpers {
  static String getInitials(String fullName) {
    final names = fullName.trim().split(' ');
    if(names.length == 1) return names.first[0];
    return names[0][0] + names[1][0];
  }

  static String capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}