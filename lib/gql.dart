const getTasksGraphQL = r"""
query getTasks($now: DateTime!, $num_queue: Int! = 10, $num_new: Int! = 10, $audio: Boolean! = false) {
  queue: progresses(order: {
    prediction: ASC
  }, filters: {
    task: {
      sentence: {
        hasAudio: $audio
      }
    },
    scheduledReview: {
      lt: $now,
    }
  }, pagination: {
    limit: $num_queue,
  }) {
    task {
    	...Exercise
  	}
  },
  new: tasks(filters: {
    new: true,
  	sentence: {
      hasAudio: $audio
    }
  }, pagination: {
    limit: $num_new
  }) {
    ...Exercise
  }
}

fragment Exercise on Task {
  id
  before
  after
  correct

  sentence {
    text
    translations {
      text
    }
    audio {
      url
    }
  }
}
""";
const attemptTaskGraphQL = r"""
mutation attemptTask($id: ID!, $success: Boolean!) {
  attempt(id: $id, success: $success) {
    lastReview
    scheduledReview
  }
}
""";
