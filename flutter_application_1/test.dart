void main() {
  try {
    String? token;
    String prefs = token!; // this throws TypeError
  } catch (e) {
    try {
      throw Exception(e.toString());
    } catch(e2) {
      print("e2: " + e2.toString());
    }
  }
}
