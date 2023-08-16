import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:langtool_mobile/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'choosecourse.dart';
import 'constants.dart';
import 'lesson.dart';


class MainScreen extends StatelessWidget {
  final Function logout;
  const MainScreen({super.key, required this.logout});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(r"""
{
  me {
    course {
      id
      known {
        code
      }
      learning {
        code
      }
    }
  }
}
"""),
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.data == null) {
          if (result.isLoading) {
            return const LoadingScreen();
          } else if (result.hasException) {
            return ErrorScreen(
              userMessage: "Could not load course information. Please check your internet connection.",
              errorMessage: result.exception.toString(),
            );
          }
        }
        if (refetch == null) {
          return const ErrorScreen(
            userMessage: "Something went wrong :(",
          );
        }

        Map<String, dynamic>? courseRaw = result.data?["me"]?["course"];
        if (courseRaw == null) {
          return ChooseCourseScreen(refetch: refetch);
        }
        Course course = Course(courseRaw["known"]["code"], courseRaw["learning"]["code"]);

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
                        builder: (context) => LessonScreen(course: course),
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
                        builder: (context) => LessonScreen(course: course, audio: true),
                      ));
                    },
                  ),
                ),
                const SizedBox(height: 10,),
                SizedBox(
                  width: 300,
                  child: CupertinoButton.filled(
                    child: const Text("Settings"),
                    onPressed: () {
                      Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) => ChooseCourseScreen(refetch: refetch, currentId: courseRaw["id"]),
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
                widget.message == null ? const SizedBox.shrink() : Text(widget.message!, style: style.copyWith(color: CupertinoColors.systemRed)),
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
                const SizedBox(height: 10),
                CupertinoButton(
                  child: const Text("Register"),
                  onPressed: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const RegisterScreen()));
                  },
                )
              ],
            )),
            Expanded(flex: 2, child: Container(),),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  
  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}
class RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordRepeatController = TextEditingController();
  String? message;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = CupertinoTheme.of(context).textTheme.textStyle;

    return Mutation(
      options: MutationOptions(
        document: gql(r"""
mutation ($username: String!, $password1: String!, $password2: String!) {
  register(data: {username: $username, password1: $password1, password2: $password2}) {
    username
  }
}"""),
        onCompleted: (resultData) {
          if (resultData != null) {
            Navigator.of(context).pop();
          }
        },
        onError: (error) {
          if (error != null && error.graphqlErrors.isNotEmpty) {
            setState(() {
              message = error.graphqlErrors[0].message;
            });
          }
        },
      ),
      builder: (runMutation, result) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text("$appName: Register"),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(flex: 2, child: Container(),),
                Expanded(flex: 8, child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    message == null ? const SizedBox.shrink() : Text(message!, style: style.copyWith(color: CupertinoColors.systemRed)),
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
                    CupertinoTextField(
                      placeholder: "Repeat password",
                      obscureText: true,
                      controller: _passwordRepeatController,
                    ),
                    const SizedBox(height: 10),
                    CupertinoButton.filled(
                      child: Text("Register", style: style),
                      onPressed: () {
                        if (_passwordRepeatController.text != "" && _passwordController.text != "" && _usernameController.text != "") {
                          runMutation({
                            "username": _usernameController.text, 
                            "password1": _passwordController.text,
                            "password2": _passwordRepeatController.text,
                          });
                        } else {
                          setState(() {
                            message = "Please fill in all required fields.";
                          });
                        }
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
                if (resultData == null) {
                  message = "Login failed, please try again later";
                }
                else if (resultData?["tokenAuth"] == null) {
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
  runApp(
    Phoenix(
      child: const Authentication(),
    ),
  );
}
