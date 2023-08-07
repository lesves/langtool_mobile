import 'package:flutter/cupertino.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';


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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            scrollDirection: Axis.vertical,
            children: [
              Text(message, style: CupertinoTheme.of(context).textTheme.textStyle),
              CupertinoButton(
                child: const Text("Reload"), 
                onPressed: () {
                  Phoenix.rebirth(context);
                }
              )
            ]
          )
        )
      )
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
