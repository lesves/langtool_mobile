import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:langtool_mobile/stats.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:audioplayers/audioplayers.dart';
import 'constants.dart';
import 'langs.dart';
import 'utils.dart';
import 'gql.dart';

const numQueue = 15;

List<dynamic> getQueue(Map<String, dynamic> data) {
  List queue = data["queue"].map((x) => x["task"]).toList() ?? [];
  List newTasks = data["new"] ?? [];

  queue.addAll(newTasks.sublist(0, numQueue-queue.length));
  return queue;
}

class LessonScreen extends StatelessWidget {
  final bool audio;

  const LessonScreen({super.key, this.audio = false});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now().toIso8601String();

    return Mutation(
      options: MutationOptions(
        document: gql(attemptTaskGraphQL),
        operationName: "attemptTask",
      ),
      builder: (runMutation, result) => Query(
        options: QueryOptions(
          document: gql(getTasksGraphQL),
          variables: {
            "now": time,
            "num_new": numQueue,
            "num_queue": numQueue,
            "audio": audio,
          },
          operationName: "getTasks",
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.hasException) {
            return ErrorScreen(message: "Error: ${result.exception.toString()}");
          }

          if (result.isLoading) {
            return const LoadingScreen();
          }

          if (result.data == null) {
            return const ErrorScreen(message: "Error: Loading failed.");
          }

          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text("Lesson"),
            ),
            child: LearnWidget(queue: getQueue(result.data!), attemptTask: runMutation)
          );
        }
      )
    );
  }
}

class LearnWidget extends StatefulWidget {
  final List<dynamic> queue;
  final TextToSpeech tts = TextToSpeech();
  final AudioPlayer player = AudioPlayer();
  final RunMutation attemptTask;

  LearnWidget({ super.key, required this.queue, required this.attemptTask });

  @override
  State<LearnWidget> createState() => LearnState();
}

enum SubmitState {
  inputting,
  incorrect,
  correct
}

class LearnState extends State<LearnWidget> {
  final List<bool> _results = [];

  int _current = 0;
  bool _correctPrefix = true;
  SubmitState _state = SubmitState.inputting;
  final TextEditingController _controller = TextEditingController();

  Map<String, dynamic> task() {
    return widget.queue[_current];
  }

  bool isLast() {
    return _current >= widget.queue.length-1;
  }

  void submit(bool answeredCorrectly) {
    widget.attemptTask({
      "id": task()["id"],
      "success": answeredCorrectly,
    });
    setState(() {
      _state = answeredCorrectly ? SubmitState.correct : SubmitState.incorrect;
    });
    if (task()["sentence"]["audio"] == null) {
      widget.tts.setLanguage("ru");
      widget.tts.speak(task()["sentence"]["text"]);
    }
    _results.add(answeredCorrectly);
  }

  void next() {
    if (isLast()) {
      Navigator.of(context).pop();
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => StatsScreen(tasks: widget.queue, results: _results)));
      return;
    }

    setState(() {
      _current += 1;
      _state = SubmitState.inputting;
    });
    _controller.value = TextEditingValue.empty;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_state != SubmitState.inputting) {
        return;
      }
      final String input = prepare(_controller.text);
      final String correct = prepare(task()["correct"]);

      if (correct == input) {
        submit(true);
      } else {
        setState(() {
          _correctPrefix = correct.startsWith(input);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fieldPaddingSize = 3.0;

    Color color;
    switch (_state) {
      case SubmitState.inputting:
        color = _correctPrefix ? CupertinoColors.systemGreen : CupertinoColors.systemRed;
        break;
      case SubmitState.incorrect:
        color = CupertinoColors.systemRed;
        _controller.value = TextEditingValue(text: task()["correct"]);
        break;
      case SubmitState.correct:
        color = CupertinoTheme.of(context).textTheme.textStyle.color ?? CupertinoColors.black;
        _controller.value = TextEditingValue(text: task()["correct"]);
        break;
    }
    final fieldStyle = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
      fontFamily: "Lora", 
      fontWeight: FontWeight.w700,
      fontSize: 30-fieldPaddingSize,
      color: color,
    );

    final textPainter = TextPainter()
      ..text = TextSpan(
        text: task()["correct"],
        style: fieldStyle,
      )
      ..textDirection = TextDirection.ltr
      ..layout(minWidth: 0, maxWidth: double.infinity);

    String actionName = "Next";
    if (_state == SubmitState.inputting) {
      actionName = "Give up";
    } else if (isLast()) {
      actionName = "Finish";
    }

    return ListView(children: [Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: CupertinoTheme.of(context).barBackgroundColor, //CupertinoColors.extraLightBackgroundGray,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Wrap(
            children: wordText(task()["before"]) + [
              SizedBox(
                width: textPainter.size.width + 10 + fieldPaddingSize,
                child: CupertinoTextField(
                  controller: _controller,
                  onSubmitted:(value) => submit(false),
                  enabled: _state == SubmitState.inputting,
                  autofocus: true,
                  autocorrect: false,
                  style: fieldStyle,
                  padding: const EdgeInsets.all(fieldPaddingSize),
                  textAlign: TextAlign.center
                ),
              ),
            ] + wordText(task()["after"])
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 16, right: 16),
            child: Column(
              children: translationTexts(task()["sentence"]["translations"])
            ),
          ),
          if (task()["sentence"]["audio"] != null)
          CupertinoButton(
            child: const Icon(CupertinoIcons.volume_up),
            onPressed: () async {
              final url = baseUrl + task()["sentence"]["audio"]["url"];
              await widget.player.play(UrlSource(url));
            }
          ),
          CupertinoButton(
            child: Text(actionName),
            onPressed: () {
              switch (_state) {
                case SubmitState.inputting:
                  submit(false);
                  break;
                case SubmitState.correct:
                case SubmitState.incorrect:
                  next();
                  break;
              }
            }
          ),
        ]
      )
    )]);
  }

  List<Widget> wordText(String text) {
     // ignore: unnecessary_cast
    return text.split(" ").map((x) => Text(
      "$x ",
      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontFamily: "Lora", fontWeight: FontWeight.w700, fontSize: 30),
      textAlign: TextAlign.center, 
    ) as Widget).toList();
  }

  List<Widget> translationTexts(List<dynamic> translations) {
    List<Widget> res = [];
    for (var t in translations) {
      res.add(Text(t["text"], style: CupertinoTheme.of(context).textTheme.textStyle));
    }
    return res;
  }
}
