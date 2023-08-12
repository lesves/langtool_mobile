import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'utils.dart';


class ChooseCourseScreen extends StatefulWidget {
  Refetch refetch;
  String? currentId;
  ChooseCourseScreen({ super.key, required this.refetch, this.currentId });

  @override
  State<ChooseCourseScreen> createState() => ChooseCourseScreenState();
}


class ChooseCourseScreenState extends State<ChooseCourseScreen> {
  int selected = 0;
  int initial = 0;

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: gql(r"""
mutation selectCourse($id: ID!) {
  setCourse(courseId: $id) {
    course {
      id
    }
  }
}
"""),
        onCompleted: (resultData) {
          widget.refetch();
          if (widget.currentId != null) {
            Navigator.of(context).pop();
          }
        },
        operationName: "selectCourse"
      ),
      builder: (runMutation, result) => Query(
        options: QueryOptions(
          document: gql(r"""
  {
    courses {
      id
      known {
        name
        nativeName
        code
      }
      learning {
        name
        nativeName
        code
      }
    }
  }
  """),
          onComplete: (data) {
            int i = widget.currentId == null ? 1 : 0;
            for (final course in data["courses"]) {
              if (course["id"] == widget.currentId) {
                setState(() {
                  initial = i;
                  selected = i;
                });
              }
              i += 1;
            }
          },
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.data == null) {
            if (result.isLoading) {
              return const LoadingScreen();
            } else if (result.hasException) {
              return ErrorScreen(message: "Could not load course information. Please check your internet connection.\n\n${result.exception.toString()}");
            }
          }
          List courses = result.data!["courses"];
          List<String> items = List.empty(growable: true);
          if (widget.currentId == null) {
            items.add("None selected");
          }

          for (final course in courses) {
            items.add("${course["known"]["name"]}-${course["learning"]["name"]}");
          }

          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text("Choose course"),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text("Choose your language course:"),
                      CupertinoButton(
                        child: Text(items[selected]),
                        onPressed: () {
                          showCupertinoModalPopup<void>(
                            context: context,
                            builder: (BuildContext context) => Container(
                              height: 216,
                              padding: const EdgeInsets.only(top: 6.0),
                              // The Bottom margin is provided to align the popup above the system navigation bar.
                              margin: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom,
                              ),
                              // Provide a background color for the popup.
                              color: CupertinoColors.systemBackground.resolveFrom(context),
                              // Use a SafeArea widget to avoid system overlaps.
                              child: SafeArea(
                                top: false,
                                child: CupertinoPicker(
                                  magnification: 1.22,
                                  squeeze: 1.2,
                                  useMagnifier: true,
                                  scrollController: FixedExtentScrollController(
                                    initialItem: initial,
                                  ),
                                  itemExtent: 30,
                                  children: items.map((x) => Text(x)).toList(),
                                  onSelectedItemChanged: (int value) {
                                    setState(() {
                                      selected = value;
                                    });
                                  },
                                ),
                              ),
                            )
                          );
                        },
                      ),
                      CupertinoButton(
                        onPressed: (widget.currentId == null && selected == 0) ? null : () {
                          runMutation({
                            "id": courses[selected - (widget.currentId == null ? 1 : 0)]["id"]
                          });
                        },
                        child: const Text("Continue")
                      )
                    ],
                  )
                )
              )
            )
          );
        },
      )
    );
  }
}