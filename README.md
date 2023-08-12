# langtool_mobile
V této části projektu se nachází klientská část aplikace pro studium jazyků.

## Struktura
V souboru `main.dart` se nachází implementace přihlašování a hlavního menu. Soubor `utils.dart` definuje `Widget`y použitelné na vícero místech, např. chybovou obrazovku. V `langs.dart` se nachází chování specifické pro různé jazyky. `lesson.dart` obsahuje nejdůležitější část, tedy vedení lekce a zkoušení slov a vět. V souboru `stats.dart` se nachází zdroj obrazovky se shrnutím úspěšnosti dané lekce. V souborech `gql.dart` a `constants.dart` se nachází konstanty a zdrojové kódy GraphQL dotazů. A nakonec v `choosecourse.dart` se řeší výběr kurzu (jazykového páru).

## Spuštění vlastního serveru
Pro provoz vlastního serveru je prozatím potřeba nastavit v `constants.dart` adresu hlavního GraphQL endpointu.

## Přihlašování
Po přihlášení se uloží získaný JWT token, který platí cca. měsíc, čímž se vylučuje opakované přihlašování při každém spuštění aplikace.
