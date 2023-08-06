
String prepare(String s, String lang) {
  s = s.toLowerCase();

  if (lang == "ru") {
    s = s.replaceAll(r"ё", r"е");
  }

  return s;
}