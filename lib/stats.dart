import 'package:flutter/cupertino.dart';

class StatsScreen extends StatelessWidget {
  final List<dynamic> tasks;
  final List<bool> results;
  const StatsScreen({super.key, required this.tasks, required this.results});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Lesson recapitulation"),
      ),
      child: SafeArea(
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) => CupertinoListTile(
            leading: results[index] ? 
              const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemGreen) :
              const Icon(CupertinoIcons.xmark, color: CupertinoColors.systemRed),
            title: Text(tasks[index]["sentence"]["text"], style: CupertinoTheme.of(context).textTheme.textStyle),
          )
        ),
      ),
    );
  }
}