import 'package:flutter/cupertino.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Loading"),
      ),
      child: Center(
        child: Text("Loading...", style: CupertinoTheme.of(context).textTheme.textStyle),
      )
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("An error has occured"),
      ),
      child: SafeArea(child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Text(message, style: CupertinoTheme.of(context).textTheme.textStyle),
      ))
    );
  }
}
