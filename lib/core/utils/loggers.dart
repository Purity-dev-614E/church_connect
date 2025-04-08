import 'dart:developer' as dev;

class AppLogger{
  static void log(String message, {String tag = 'APP'}){
    dev.log('[$tag] $message');
  }

  static void error(String message, {String tag = 'ERROR'}) {
    dev.log('[$tag] ❌ $message');
  }

  static void warning(String message, {String tag = 'WARNING'}) {
    dev.log('[$tag] ⚠️ $message');
  }

  static void info(String message, {String tag = 'INFO'}) {
    dev.log('[$tag] 📝 $message');
  }
}