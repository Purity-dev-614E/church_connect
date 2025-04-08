class Validators{
  static bool isValidEmail(String email){
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return regex.hasMatch(email);
  }

  static bool isValidPhone (String phone){
    final regex = RegExp(r"^\+?[0-9]{10,15}$");
    return regex.hasMatch(phone);
  }

  static bool isNotEmpty (String input){
    return input.trim().isNotEmpty;
  }

  static bool isValidPassword (String password){
    final regex = RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$");
    return regex.hasMatch(password);
  }

}