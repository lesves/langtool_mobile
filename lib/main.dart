import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'lesson.dart';


class MainScreen extends StatelessWidget {
  final Function logout;
  const MainScreen({super.key, required this.logout});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(appName),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: CupertinoButton.filled(
                child: const Text("Start lesson"),
                onPressed: () {
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) => const LessonScreen(),
                  ));
                },
              ),
            ),
            const SizedBox(height: 10,),
            SizedBox(
              width: 300,
              child: CupertinoButton.filled(
                child: const Text("Start listening lesson"),
                onPressed: () {
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) => const LessonScreen(audio: true),
                  ));
                },
              ),
            ),
            const SizedBox(height: 10,),
            SizedBox(
              width: 300,
              child: CupertinoButton.filled(
                onPressed: () {logout();},
                child: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final Function onSubmit;
  final String? message;

  const LoginScreen({super.key, required this.onSubmit, required this.message});
  
  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = CupertinoTheme.of(context).textTheme.textStyle;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("$appName: Login"),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(flex: 2, child: Container(),),
            Expanded(flex: 8, child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.message == null ? const SizedBox.shrink() : Text(widget.message!),
                const SizedBox(height: 10),
                CupertinoTextField(
                  placeholder: "Username",
                  autocorrect: false,
                  controller: _usernameController,
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  placeholder: "Password",
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 10),
                CupertinoButton.filled(
                  child: Text("Login", style: style),
                  onPressed: () {
                    widget.onSubmit(_usernameController.text, _passwordController.text);
                  },
                ),
              ],
            )),
            Expanded(flex: 2, child: Container(),),
          ],
        ),
      ),
    );
  }
}

class Authentication extends StatefulWidget {
  const Authentication({ super.key });

  @override
  State<Authentication> createState() => AuthenticationState();
}

class AuthenticationState extends State<Authentication> {
  String? token;
  String? message;

  @override
  void initState() {
    super.initState();
    setupStoredToken();
  }

  void setupStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
    });
  }

  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink(
      endpoint,
    );

    final AuthLink authLink = AuthLink(
      getToken: () async => token != null ? "Bearer $token" : ""
    );

    final Link link = authLink.concat(httpLink);
    
    final ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(),
      ),
    );
    
    return GraphQLProvider(
      client: client,
      child: CupertinoApp(
        title: appName,
        home: token != null ? MainScreen(logout: () async {
          setState(() {
            token = null;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove("token");
        }) : Mutation(
          options: MutationOptions(
            document: gql(r"""
mutation ($username: String!, $password: String!) {
tokenAuth(username: $username, password: $password)
}
            """),
            onCompleted: (dynamic resultData) async {
              setState(() {
                if (resultData?["tokenAuth"] == null) {
                  message = "Invalid username or password";
                }
                token = resultData?["tokenAuth"];
              });
              if (resultData?["tokenAuth"] != null) {
                final prefs = await SharedPreferences.getInstance();
                prefs.setString("token", resultData?["tokenAuth"]);
              }
            }
          ),
          builder: (runMutation, result) {
            return LoginScreen(
              message: message,
              onSubmit: (username, password) {
                runMutation({
                  "username": username,
                  "password": password,
                });
              }
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(const Authentication());
}
