import 'package:intl/intl.dart';

class Formatters{
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

 static String formatPhone(String phone) {
   if (phone.startsWith('+254')) {
     return phone.replaceAll(new RegExp(r'[^0-9]'), '');
   } else {
     throw FormatException('Phone number must start with +254');
   }
 }
}