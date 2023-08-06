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

class FinishScreen extends StatelessWidget {
  const FinishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("No new tasks available"),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "🎉",
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontSize: 128),
                ),
                Text(
                  "Currently, there are no more tasks you can do. Please come again later.", 
                  style: CupertinoTheme.of(context).textTheme.textStyle
                ),
              ]
            )
          )
        )
      )
    );
  }
}
