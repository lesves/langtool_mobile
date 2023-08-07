const getWordsGraphQL = r"""
query getWords(
  $now: DateTime!, 
  $known: String,
  $learning: String!
  $num_queue: Int! = 10, 
  $num_new: Int! = 10, 
  $audio: Boolean! = false
) {
  queue: progresses(
    order: {prediction: ASC}
    filters: {
      scheduledReview: {lt: $now}
      word: {
        lang: {
          code: $learning
        }
      }
    }
    pagination: {limit: $num_queue}
  ) {
    scheduledReview
    word {
			...Exercise
    }
  }
  new: words(
    filters: {
      new: true,
      lang: {
        code: $learning
      }
    }, 
    order: {
      freq: DESC
    }
    pagination: {limit: $num_new}
  ) {
    ...Exercise
  }
}

fragment Exercise on Word {
  id
  text
  sentence: randomSentence(filters: {
    hasAudio: $audio,
    translations: {
      lang: {
        code: $known
      }
    }
  }) {
    text
    tokens
    lemmas
    spans
    translations(filters: {
      lang: {code: $known}
    }) 
    {
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
