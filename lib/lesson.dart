import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:langtool_mobile/stats.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:audioplayers/audioplayers.dart';
import 'constants.dart';
import 'langs.dart';
import 'utils.dart';
import 'gql.dart';


class Task {
  late String id;
  late String word;

  late String text;

  late String before;
  late String correct;
  late String after;

  late String? audio;

  late List<String> translations;

  Task.fromWord(Map<String, dynamic> data) {
    id = data["id"];

    word = data["text"];
    text = data["sentence"]["text"];

    int wordIdx = data["sentence"]["lemmas"].indexOf(word);

    int hiddenStart = data["sentence"]["spans"][wordIdx][0];
    int hiddenStop = data["sentence"]["spans"][wordIdx][1];

    correct = text.substring(hiddenStart, hiddenStop);
    before = text.substring(0, hiddenStart);
    after = text.substring(hiddenStop);

    audio = data["sentence"]["audio"]?["url"];

    translations = data["sentence"]["translations"].map((x) => x["text"]).whereType<String>().toList();
  }
}

List<Task> getQueue(Map<String, dynamic> data) {
  if (data["queue"] == null || data["new"] == null) {
    throw Exception("todo");
  }

  List<dynamic> rawQueue = data["queue"].where((x) => x["word"]["sentence"] != null).toList();
  List<dynamic> rawNew = data["new"].where((x) => x["sentence"] != null).toList();

  List<Task> queue = List.empty(growable: true);

  for (Map<String, dynamic> progress in rawQueue) {
    queue.add(Task.fromWord(progress["word"]));
  }

  for (Map<String, dynamic> data in rawNew) {
    queue.add(Task.fromWord(data));
  }

  return queue;
}

class Course {
  final String known;
  final String learning;

  const Course(this.known, this.learning);
}

class LessonScreen extends StatelessWidget {
  final bool audio;

  final Course course;

  const LessonScreen({super.key, this.audio = false, required this.course});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now().toIso8601String();

    return Mutation(
      options: MutationOptions(
        document: gql(attemptGraphQL),
        operationName: "attempt",
      ),
      builder: (runMutation, result) => Query(
        options: QueryOptions(
          document: gql(getWordsGraphQL),
          variables: {
            "now": time,
            "num_new": numQueue,
            "num_queue": numQueue,
            "audio": audio,
            "known": audio ? null : course.known,
            "learning": course.learning
          },
          operationName: "getWords",
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) {
            return const LoadingScreen();
          }

          if (result.hasException || result.data == null) {
            return ErrorScreen(
              userMessage: "Failed to load lesson data. Please check your internet connection.",
              errorMessage: result.exception.toString()
            );
          }

          var queue = getQueue(result.data!);
          if (queue.isEmpty) {
            return const FinishScreen();
          }

          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text("Lesson"),
            ),
            child: LearnWidget(queue: queue, course: course, attempt: runMutation)
          );
        }
      )
    );
  }
}

class LearnWidget extends StatefulWidget {
  final List<Task> queue;
  final Course course;

  final TextToSpeech tts = TextToSpeech();
  final AudioPlayer player = AudioPlayer();
  final RunMutation attempt;

  LearnWidget({ super.key, required this.queue, required this.course, required this.attempt });

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

  Task task() {
    return widget.queue[_current];
  }

  bool isLast() {
    return _current >= widget.queue.length-1;
  }

  void submit(bool answeredCorrectly) {
    widget.attempt({
      "id": task().id,
      "success": answeredCorrectly,
    });
    setState(() {
      _state = answeredCorrectly ? SubmitState.correct : SubmitState.incorrect;
    });
    if (task().audio == null) {
      widget.tts.setLanguage(widget.course.learning);
      widget.tts.speak(task().text);
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
      final String input = prepare(_controller.text, widget.course.learning);
      final String correct = prepare(task().correct, widget.course.learning);

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
        _controller.value = TextEditingValue(text: task().correct);
        break;
      case SubmitState.correct:
        color = CupertinoTheme.of(context).textTheme.textStyle.color ?? CupertinoColors.black;
        _controller.value = TextEditingValue(text: task().correct);
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
        text: task().correct,
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
            children: wordText(task().before) + [
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
            ] + wordText(task().after)
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 16, right: 16),
            child: Column(
              children: task().translations.map(
                (t) => Text(t, style: CupertinoTheme.of(context).textTheme.textStyle)
              ).toList()
            ),
          ),
          if (task().audio != null)
          CupertinoButton(
            child: const Icon(CupertinoIcons.volume_up),
            onPressed: () async {
              final url = baseUrl + task().audio!;
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
}
