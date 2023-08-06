const getWordsGraphQL = r"""
query getWords($now: DateTime!, $num_queue: Int! = 10, $num_new: Int! = 10, $audio: Boolean! = false) {
  queue: progresses(
    order: {prediction: ASC}
    filters: {scheduledReview: {lt: $now}}
    pagination: {limit: $num_queue}
  ) {
    scheduledReview
    word {
			...Exercise
    }
  }
  new: words(filters: {new: true}, pagination: {limit: $num_new}) {
    ...Exercise
  }
}

fragment Exercise on Word {
  id
  text
  sentence: randomSentence(filters: {hasAudio: $audio}) {
    text
    tokens
    lemmas
    spans
    translations {
      text
    }
    audio {
      url
    }
  }
}
""";
const attemptGraphQL = r"""
mutation attempt($id: ID!, $success: Boolean!) {
  attempt(id: $id, success: $success) {
    lastReview
    scheduledReview
  }
}
""";
