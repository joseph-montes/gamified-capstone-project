// ─────────────────────────────────────────────
//  challenge_model.dart
//  Data models for Challenges and Questions.
// ─────────────────────────────────────────────

class Question {
  final String questionText;
  final String? codeSnippet;
  final List<String> options;
  final int correctAnswerIndex;

  const Question({
    required this.questionText,
    this.codeSnippet,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionText: map['questionText'] as String? ?? '',
      codeSnippet: map['codeSnippet'] as String?,
      options: List<String>.from(map['options'] as List? ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] as int? ?? 0,
    );
  }
}

class Challenge {
  final String id;
  final String title;
  final String topic;
  final String difficulty;
  final int xpReward;
  final List<Question> questions;

  const Challenge({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.xpReward,
    required this.questions,
  });

  factory Challenge.fromMap(Map<String, dynamic> map, String documentId) {
    final rawQuestions = map['questions'] as List? ?? [];
    return Challenge(
      id: documentId,
      title: map['title'] as String? ?? 'Untitled Challenge',
      topic: map['topic'] as String? ?? 'General',
      difficulty: map['difficulty'] as String? ?? 'Easy',
      xpReward: map['xpReward'] as int? ?? 50,
      questions: rawQuestions
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Single dummy for Home/testing ─────────
  static Challenge dummy() => allChallenges().first;

  /// Finds the next uncompleted challenge for the user.
  /// Prefers same category/tag, falls back to any uncompleted.
  Challenge? findNextChallenge(dynamic user) {
    final completedIds =
        (user?.completedChallengeIds as List<String>?) ?? <String>[];
    final all = allChallenges();

    // Category prefix (first segment before '_')
    final myPrefix = id.split('_').first;

    // 1. Try same category but not yet completed
    final sameCat = all.where(
      (c) => c.id.startsWith(myPrefix) && !completedIds.contains(c.id) && c.id != id,
    ).toList();
    if (sameCat.isNotEmpty) return sameCat.first;

    // 2. Fall back to any uncompleted challenge
    final any = all.where(
      (c) => !completedIds.contains(c.id) && c.id != id,
    ).toList();
    if (any.isNotEmpty) return any.first;

    return null; // all challenges done!
  }

  // ── Full challenge catalogue ───────────────
  static List<Challenge> allChallenges() => [
        // ── Python ─────────────────────────────
        const Challenge(
          id: 'py_easy_01',
          title: 'Python Fundamentals',
          topic: 'Variables & Data Types',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'What is the output of the following code?',
              codeSnippet: 'x = 10\ny = 3\nprint(x // y)',
              options: ['3', '3.33', '4', '1'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which is the correct way to declare a string?',
              options: [
                "String name = 'Alice'",
                "name = 'Alice'",
                "str name = 'Alice'",
                "var name = 'Alice'",
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does len() return on a list?',
              codeSnippet: 'my_list = [1, 2, 3, 4, 5]\nprint(len(my_list))',
              options: [
                'The sum of elements',
                'The number of elements',
                'The last element',
                'The first element',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which keyword defines a function in Python?',
              options: ['function', 'func', 'def', 'define'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What will this code print?',
              codeSnippet: 'for i in range(3):\n    print(i)',
              options: ['1 2 3', '0 1 2', '0 1 2 3', '1 2 3 4'],
              correctAnswerIndex: 1,
            ),
          ],
        ),
        const Challenge(
          id: 'py_easy_02',
          title: 'Loops & Lists',
          topic: 'Control Flow',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'What does this code print?',
              codeSnippet: 'nums = [1, 2, 3]\nprint(nums[-1])',
              options: ['1', '2', '3', 'Error'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'How do you add an item to a list?',
              options: [
                'list.add(item)',
                'list.append(item)',
                'list.push(item)',
                'list.insert(item)',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is the output?',
              codeSnippet: 'total = 0\nfor i in range(1, 4):\n    total += i\nprint(total)',
              options: ['3', '6', '10', '4'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which loop runs at least once?',
              options: ['for loop', 'while loop', 'do-while loop', 'None'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What keyword exits a loop immediately?',
              options: ['exit', 'stop', 'break', 'continue'],
              correctAnswerIndex: 2,
            ),
          ],
        ),
        const Challenge(
          id: 'py_medium_01',
          title: 'Functions & Scope',
          topic: 'Functions',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'What is the output?',
              codeSnippet: 'def greet(name="World"):\n    return f"Hello, {name}!"\nprint(greet())',
              options: [
                'Hello, name!',
                'Hello, World!',
                'Error',
                'Hello, !',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does *args allow?',
              options: [
                'Variable keyword arguments',
                'Variable positional arguments',
                'Default arguments',
                'None of the above',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is a lambda function?',
              options: [
                'A class method',
                'A named function',
                'An anonymous one-line function',
                'A recursive function',
              ],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is the output?',
              codeSnippet: 'x = 10\ndef foo():\n    x = 20\nfoo()\nprint(x)',
              options: ['20', '10', 'Error', 'None'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which keyword makes a variable global inside a function?',
              options: ['global', 'nonlocal', 'extern', 'public'],
              correctAnswerIndex: 0,
            ),
          ],
        ),
        const Challenge(
          id: 'py_hard_01',
          title: 'Class Inheritance',
          topic: 'OOP',
          difficulty: 'Hard',
          xpReward: 200,
          questions: [
            Question(
              questionText: 'What does super() do?',
              options: [
                'Creates a superclass instance',
                'Calls the parent class method',
                'Makes a class abstract',
                'Overrides a method',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is the output?',
              codeSnippet:
                  'class A:\n    def hello(self): return "A"\nclass B(A):\n    def hello(self): return "B"\nb = B()\nprint(b.hello())',
              options: ['A', 'B', 'A B', 'Error'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is polymorphism?',
              options: [
                'Multiple inheritance',
                'Same interface, different behaviour',
                'Hiding data',
                'Using multiple classes',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which method is called when an object is created?',
              options: ['__start__', '__new__', '__init__', '__create__'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What prefix makes an attribute private?',
              options: ['#', '__', '@', '!'],
              correctAnswerIndex: 1,
            ),
          ],
        ),

        // ── Java ───────────────────────────────
        const Challenge(
          id: 'java_easy_01',
          title: 'Java Basics',
          topic: 'Variable Operators',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'Which type stores whole numbers in Java?',
              options: ['float', 'double', 'int', 'char'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is the output?',
              codeSnippet: 'int x = 5;\nSystem.out.println(x++);',
              options: ['5', '6', '4', 'Error'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'How do you print in Java?',
              options: [
                'print("Hello")',
                'console.log("Hello")',
                'System.out.println("Hello")',
                'echo "Hello"',
              ],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which operator checks equality?',
              options: ['=', ':=', '==', '!='],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is the default value of an int in Java?',
              options: ['null', '1', '0', 'undefined'],
              correctAnswerIndex: 2,
            ),
          ],
        ),
        const Challenge(
          id: 'java_medium_01',
          title: 'OOP Principles',
          topic: 'Object-Oriented Programming',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'What is encapsulation?',
              options: [
                'Inheriting from multiple classes',
                'Bundling data and methods together',
                'Overriding methods',
                'Creating interfaces',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which keyword is used for inheritance?',
              options: ['implements', 'extends', 'inherits', 'super'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is an interface?',
              options: [
                'A class with implementation',
                'A blueprint with method signatures only',
                'An abstract class',
                'A private class',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which access modifier is most restrictive?',
              options: ['public', 'protected', 'private', 'default'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is method overloading?',
              options: [
                'Same name, different parameters',
                'Overriding a parent method',
                'Hiding a method',
                'Using abstract methods',
              ],
              correctAnswerIndex: 0,
            ),
          ],
        ),

        // ── SQL ────────────────────────────────
        const Challenge(
          id: 'sql_medium_01',
          title: 'SELECT Queries',
          topic: 'Database SQL',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'Which clause filters rows in a SELECT?',
              options: ['HAVING', 'WHERE', 'GROUP BY', 'ORDER BY'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does SELECT DISTINCT do?',
              options: [
                'Returns all rows',
                'Returns unique values only',
                'Filters NULLs',
                'Orders results',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which aggregate counts all rows?',
              options: ['SUM(*)', 'COUNT(*)', 'AVG(*)', 'MAX(*)'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does ORDER BY name DESC do?',
              options: [
                'Sorts A→Z',
                'Sorts Z→A',
                'Groups by name',
                'Filters names',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which clause filters grouped results?',
              options: ['WHERE', 'HAVING', 'FILTER', 'LIMIT'],
              correctAnswerIndex: 1,
            ),
          ],
        ),
        const Challenge(
          id: 'sql_hard_01',
          title: 'JOINs & Subqueries',
          topic: 'Database SQL',
          difficulty: 'Hard',
          xpReward: 200,
          questions: [
            Question(
              questionText: 'Which JOIN returns only matching rows?',
              options: ['LEFT JOIN', 'RIGHT JOIN', 'INNER JOIN', 'FULL JOIN'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What does a subquery return?',
              options: [
                'A table only',
                'A scalar, row, or table',
                'Only a single value',
                'Nothing',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which keyword is used with a subquery to check existence?',
              options: ['IN', 'EXISTS', 'LIKE', 'BETWEEN'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does LEFT JOIN return?',
              options: [
                'Only matched rows',
                'All left rows + matched right rows',
                'All right rows',
                'All rows from both tables',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is a CROSS JOIN?',
              options: [
                'Joins on a condition',
                'Cartesian product of two tables',
                'Joins on primary key',
                'Removes duplicates',
              ],
              correctAnswerIndex: 1,
            ),
          ],
        ),

        // ── Networking ─────────────────────────
        const Challenge(
          id: 'net_easy_01',
          title: 'IP Address Basics',
          topic: 'Networking',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'How many bits does an IPv4 address have?',
              options: ['8', '16', '32', '64'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What does DNS stand for?',
              options: [
                'Dynamic Network System',
                'Domain Name System',
                'Data Network Service',
                'Digital Name Server',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which IP address is localhost?',
              options: ['192.168.0.1', '127.0.0.1', '0.0.0.0', '255.255.255.255'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What port does HTTP use?',
              options: ['443', '21', '80', '22'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What does DHCP do?',
              options: [
                'Resolves domain names',
                'Assigns IP addresses automatically',
                'Encrypts traffic',
                'Routes packets',
              ],
              correctAnswerIndex: 1,
            ),
          ],
        ),

        // 1. ── Java Hard ───────────────
        const Challenge(
          id: 'java_hard_01',
          title: 'Java Concurrency',
          topic: 'Multithreading',
          difficulty: 'Hard',
          xpReward: 200,
          questions: [
            Question(
              questionText: 'Which method must be implemented by the Runnable interface?',
              options: ['start()', 'run()', 'execute()', 'thread()'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does the synchronized keyword do?',
              options: [
                'Speeds up the execution',
                'Allows multiple threads to enter simultaneously',
                'Prevents thread interference and memory consistency errors',
                'Restarts the application',
              ],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'How do you correctly start a thread created via Runnable?',
              options: [
                'myRunnable.start()',
                'new Thread(myRunnable).start()',
                'myRunnable.run()',
                'new Thread().run(myRunnable)',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which class is used for atomic operations in Java?',
              options: ['AtomicInteger', 'SyncInteger', 'SafeInt', 'LockInteger'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'What is a deadlock?',
              options: [
                'When a thread terminates unexpectedly',
                'When two or more threads are blocked forever, waiting for each other',
                'When a CPU core gets locked',
                'When synchronized code runs too slowly',
              ],
              correctAnswerIndex: 1,
            ),
          ],
        ),

        // 2. ── JavaScript Basics ───────────────
        const Challenge(
          id: 'js_easy_01',
          title: 'JavaScript Fundamentals',
          topic: 'Basic JS',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'Which symbol is used for comments in JavaScript?',
              options: ['<!-- -->', '//', '/*', '#'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which keyword creates a variable that cannot be reassigned?',
              options: ['var', 'let', 'const', 'final'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is the output of 2 + "2"?',
              options: ['4', '"4"', '"22"', 'NaN'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'How do you write "Hello World" in an alert box?',
              options: ['msgBox("Hello World");', 'alert("Hello World");', 'msg("Hello World");', 'alertBox("Hello World");'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which operator checks both value and type?',
              options: ['==', '=', '===', '!='],
              correctAnswerIndex: 2,
            ),
          ],
        ),

        // 3. ── JavaScript Async ───────────────
        const Challenge(
          id: 'js_medium_01',
          title: 'Promises & Async/Await',
          topic: 'JS Callbacks',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'Which state is NOT a part of a Promise?',
              options: ['Pending', 'Fulfilled', 'Rejected', 'Waiting'],
              correctAnswerIndex: 3,
            ),
            Question(
              questionText: 'What keyword replaces .then() chaining?',
              options: ['catch', 'await', 'async', 'defer'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'How do you catch an error when using async/await?',
              options: ['try/catch', '.catch() block', 'onError', 'try/except'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'What does Promise.all() do?',
              options: [
                'Resolves only if all promises resolve',
                'Resolves if any promise resolves',
                'Rejects only if all promises reject',
                'Returns the first promise to finish',
              ],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'What does the fetch() method return by default?',
              options: ['JSON data', 'A Promise', 'HTML text', 'An array'],
              correctAnswerIndex: 1,
            ),
          ],
        ),

        // 4. ── Git Basics ───────────────
        const Challenge(
          id: 'git_easy_01',
          title: 'Git Version Control',
          topic: 'Git',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'Which command initializes a new Git repository?',
              options: ['git start', 'git init', 'git new', 'git create'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'How do you check the state of your working directory?',
              options: ['git status', 'git check', 'git log', 'git info'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'What command is used to save your changes to the local repository?',
              options: ['git add', 'git push', 'git commit', 'git save'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which command downloads repository history from a remote?',
              options: ['git push', 'git pull', 'git fetch', 'Both pull and fetch'],
              correctAnswerIndex: 3,
            ),
            Question(
              questionText: 'What is a branch in Git?',
              options: [
                'A new repository',
                'A movable pointer to a commit',
                'A deleted commit',
                'A tag',
              ],
              correctAnswerIndex: 1,
            ),
          ],
        ),

        // 5. ── Linux Basics ───────────────
        const Challenge(
          id: 'linux_easy_01',
          title: 'Linux Commands',
          topic: 'OS & Terminal',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'Which command lists files in a directory?',
              options: ['dir', 'list', 'ls', 'show'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'How do you change your current directory?',
              options: ['cd', 'mv', 'ch', 'dr'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which command is used to remove a file?',
              options: ['delete', 'rm', 'remove', 'clean'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does the "pwd" command stand for?',
              options: ['Password', 'Public Web Domain', 'Print Working Directory', 'Parse Word Data'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which command prints the contents of a file to the screen?',
              options: ['view', 'cat', 'print', 'read'],
              correctAnswerIndex: 1,
            ),
          ],
        ),

        // 6. ── HTML/CSS ───────────────
        const Challenge(
          id: 'web_easy_01',
          title: 'HTML & CSS Basics',
          topic: 'Web Design',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'What does HTML stand for?',
              options: [
                'Hyper Text Markup Language',
                'High Tech Modern Layout',
                'Hyperlinks and Text Markup Language',
                'Home Tool Markup Language'
              ],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which HTML tag is used for the largest heading?',
              options: ['<head>', '<heading>', '<h6>', '<h1>'],
              correctAnswerIndex: 3,
            ),
            Question(
              questionText: 'What property is used to change the text color in CSS?',
              options: ['text-color', 'font-color', 'color', 'fgcolor'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which tag is used to create a hyperlink?',
              options: ['<link>', '<a>', '<href>', '<url>'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which CSS property controls the spacing outside an element border?',
              options: ['padding', 'margin', 'spacing', 'border-spacing'],
              correctAnswerIndex: 1,
            ),
          ],
        ),

        // 7. ── C++ Pointers ───────────────
        const Challenge(
          id: 'cpp_medium_01',
          title: 'Pointers & References',
          topic: 'C++ Memory',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'Which operator is used to get the memory address of a variable?',
              options: ['*', '&', '->', '#'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does the dereference operator do?',
              options: [
                'Gets the address of a pointer',
                'Deletes a pointer from memory',
                'Accesses the value at the pointer\'s address',
                'Creates a reference',
              ],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'How do you dynamically allocate memory for an array in C++?',
              options: ['alloc()', 'malloc()', 'new', 'create'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is a memory leak?',
              options: [
                'When a pointer points to NULL',
                'When allocated memory is never freed',
                'When the stack overflows',
                'When a program crashes',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which keyword frees dynamically allocated memory in C++?',
              options: ['garbage', 'free', 'remove', 'delete'],
              correctAnswerIndex: 3,
            ),
          ],
        ),

        // 8. ── Python Hard ───────────────
        const Challenge(
          id: 'py_hard_02',
          title: 'Advanced Python Concepts',
          topic: 'Generators & Decorators',
          difficulty: 'Hard',
          xpReward: 200,
          questions: [
            Question(
              questionText: 'Which keyword is used inside a generator function?',
              options: ['return', 'yield', 'next', 'generate'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is the main advantage of generators over lists?',
              options: [
                'They are faster to sort',
                'They use less memory by yielding values lazily',
                'They support multi-threading natively',
                'They can be indexed',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does a decorator do in Python?',
              options: [
                'Modifies the behavior of a function or class',
                'Styles the terminal output',
                'Comments out a block of code',
                'Deletes unused variables',
              ],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'What does the __call__ magic method do?',
              options: [
                'Makes an instance callable like a function',
                'Creates a new class',
                'Triggers when a system call is made',
                'Replaces the __init__ method',
              ],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which module provides deep copy functionality?',
              options: ['sys', 'deepcopy', 'copy', 'clone'],
              correctAnswerIndex: 2,
            ),
          ],
        ),

        // 9. ── SQL Hard ───────────────
        const Challenge(
          id: 'sql_hard_02',
          title: 'Window Functions',
          topic: 'Advanced SQL',
          difficulty: 'Hard',
          xpReward: 200,
          questions: [
            Question(
              questionText: 'Which keyword activates a window function?',
              options: ['WINDOW', 'OVER', 'GROUP BY', 'PARTITION'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is the difference between RANK() and DENSE_RANK()?',
              options: [
                'RANK skips numbers after ties, DENSE_RANK does not',
                'DENSE_RANK is faster',
                'There is no difference',
                'RANK is for numbers, DENSE_RANK is for strings',
              ],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which clause divides a window into smaller sets?',
              options: ['OVER', 'ORDER BY', 'PARTITION BY', 'GROUP BY'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What does the LEAD() function do?',
              options: [
                'Finds the max value in a column',
                'Accesses row data from a subsequent row without a self-join',
                'Sets the primary key',
                'Navigates to previous rows',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does ROW_NUMBER() do?',
              options: [
                'Counts total rows in the table',
                'Sums up the values of a column',
                'Returns the primary key ID',
                'Assigns a unique sequential integer to rows within a partition',
              ],
              correctAnswerIndex: 3,
            ),
          ],
        ),

        // 10. ── Cybersecurity ───────────────
        const Challenge(
          id: 'sec_easy_01',
          title: 'Cybersecurity Basics',
          topic: 'InfoSec',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'What does CIA stand for in security?',
              options: [
                'Central Intelligence Agency',
                'Confidentiality, Integrity, Availability',
                'Code, Implementation, Architecture',
                'Computer Internet Access',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is phishing?',
              options: [
                'A network attack targeting routers',
                'A virus affecting word documents',
                'Exploiting a software bug securely',
                'Fraudulent communication tricking humans to reveal data',
              ],
              correctAnswerIndex: 3,
            ),
            Question(
              questionText: 'What does a Firewall do?',
              options: [
                'Increases download speed',
                'Monitors and filters incoming and outgoing network traffic',
                'Stores backups offsite',
                'Removes malware',
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is the most common cause of data breaches?',
              options: ['Weak passwords and human error', 'Hardware failure', 'Zero-day exploits', 'DDoS attacks'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which protocol secures web traffic?',
              options: ['HTTP', 'FTP', 'HTTPS', 'Telnet'],
              correctAnswerIndex: 2,
            ),
          ],
        ),

        // ── Additional 10 New Challenges ───────────────
        const Challenge(
          id: 'java_medium_02',
          title: 'Java Exception Handling',
          topic: 'Error Handling',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'Which block always executes, regardless of an exception?',
              options: ['try', 'catch', 'finally', 'throws'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which keyword is used to explicitly throw an exception?',
              options: ['try', 'catch', 'throw', 'throws'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is the base class for all exceptions in Java?',
              options: ['Error', 'Exception', 'Throwable', 'RuntimeException'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which exception occurs when dividing by zero?',
              options: ['ArithmeticException', 'NullPointerException', 'NumberFormatException', 'IllegalArgumentException'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which keyword in a method signature indicates it might throw an exception?',
              options: ['throw', 'throws', 'catch', 'finally'],
              correctAnswerIndex: 1,
            ),
          ],
        ),
        const Challenge(
          id: 'py_medium_02',
          title: 'Dictionaries & Sets',
          topic: 'Data Structures',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'How do you create an empty dictionary?',
              options: ['{}', '[]', '()', 'set()'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'What method returns a copy of dictionary keys?',
              options: ['.keys()', '.values()', '.items()', '.get()'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which data structure does not allow duplicate values?',
              options: ['List', 'Tuple', 'Set', 'Dictionary'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'How do you add a key-value pair to a dictionary `d`?',
              options: ['d.add(k,v)', 'd.append(k,v)', 'd[k] = v', 'd.insert(k,v)'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is the output of `set([1, 2, 2, 3])`?',
              options: ['[1, 2, 2, 3]', '{1, 2, 3}', '{1, 2, 2, 3}', 'Error'],
              correctAnswerIndex: 1,
            ),
          ],
        ),
        const Challenge(
          id: 'sql_easy_01',
          title: 'SQL Table Basics',
          topic: 'DDL Basics',
          difficulty: 'Easy',
          xpReward: 50,
          questions: [
            Question(
              questionText: 'Which command creates a new table?',
              options: ['MAKE TABLE', 'CREATE TABLE', 'ADD TABLE', 'NEW TABLE'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which constraint ensures a column cannot have NULL values?',
              options: ['UNIQUE', 'NOT NULL', 'PRIMARY KEY', 'CHECK'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'How do you delete a whole table?',
              options: ['DROP TABLE', 'DELETE TABLE', 'REMOVE TABLE', 'TRUNCATE TABLE'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which command adds a new column to a table?',
              options: ['UPDATE TABLE', 'MODIFY TABLE', 'ALTER TABLE', 'CHANGE TABLE'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What does TRUNCATE TABLE do?',
              options: [
                'Deletes the table structure',
                'Deletes all rows without logging individual row deletes',
                'Removes the last row added',
                'Hides the table'
              ],
              correctAnswerIndex: 1,
            ),
          ],
        ),
        const Challenge(
          id: 'js_hard_01',
          title: 'Closures & Prototypes',
          topic: 'Advanced JS',
          difficulty: 'Hard',
          xpReward: 200,
          questions: [
            Question(
              questionText: 'What is a closure in JavaScript?',
              options: [
                'A function that has access to its outer function scope even after the outer function has returned',
                'A way to close browser windows',
                'A loop that terminates early',
                'A private variable'
              ],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'How does inheritance work in JavaScript?',
              options: ['Class-based', 'Interface-based', 'Prototypal', 'Multiple-inheritance'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What evaluates to false in JS?',
              options: ['"false"', '0', '[]', '{}'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is the purpose of the `bind()` method?',
              options: [
                'Combines two arrays',
                'Creates a new function that, when called, has its `this` keyword set to the provided value',
                'Attaches an event listener',
                'Binds a variable to a specific type'
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does `Object.create(null)` do?',
              options: [
                'Throws an error',
                'Creates an empty object with a normal prototype chain',
                'Creates an object with no prototype (no inherited properties)',
                'Creates a null object'
              ],
              correctAnswerIndex: 2,
            ),
          ],
        ),
        const Challenge(
          id: 'web_medium_01',
          title: 'CSS Flexbox & Layouts',
          topic: 'Advanced CSS',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'Which property aligns flex items along the main axis?',
              options: ['align-items', 'justify-content', 'align-content', 'flex-direction'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which value specifies a column layout in Flexbox?',
              options: ['flex-direction: column', 'display: column', 'flex: col', 'align: vertical'],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'What does `flex-grow: 1` do?',
              options: [
                'Allows an item to grow and fill available space',
                'Makes text larger',
                'Prevents an item from shrinking',
                'Increases the flex-basis by 1px'
              ],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which property aligns items along the cross axis?',
              options: ['justify-content', 'align-items', 'flex-wrap', 'order'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'To use Flexbox on a container, you must set:',
              options: ['position: relative', 'display: grid', 'display: flex', 'float: left'],
              correctAnswerIndex: 2,
            ),
          ],
        ),
        const Challenge(
          id: 'linux_medium_01',
          title: 'Linux File Permissions',
          topic: 'OS & Security',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'Which command changes file permissions?',
              options: ['chown', 'chmod', 'chgrp', 'attrib'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does permission `777` mean?',
              options: [
                'Read-only for everyone',
                'Read, write, execute for user, read for others',
                'Read, write, and execute for everyone',
                'Hidden file'
              ],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which command changes the owner of a file?',
              options: ['chmod', 'chgrp', 'passwd', 'chown'],
              correctAnswerIndex: 3,
            ),
            Question(
              questionText: 'In `ls -l`, what does the first character `d` mean?',
              options: ['Deleted', 'Document', 'Directory', 'Data'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which numeric value represents write permission?',
              options: ['1', '2', '4', '8'],
              correctAnswerIndex: 1,
            ),
          ],
        ),
        const Challenge(
          id: 'net_medium_01',
          title: 'OSI Model Basics',
          topic: 'Networking',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'How many layers are in the OSI model?',
              options: ['4', '5', '7', '9'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'Which layer is responsible for routing?',
              options: ['Data Link', 'Network', 'Transport', 'Application'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'TCP and UDP operate at which layer?',
              options: ['Network', 'Transport', 'Session', 'Data Link'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which layer uses MAC addresses?',
              options: ['Physical', 'Data Link', 'Network', 'Transport'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'HTTP, FTP, and SMTP operate at which layer?',
              options: ['Session', 'Presentation', 'Application', 'Transport'],
              correctAnswerIndex: 2,
            ),
          ],
        ),
        const Challenge(
          id: 'git_medium_01',
          title: 'Branching & Merging',
          topic: 'Advanced Git',
          difficulty: 'Medium',
          xpReward: 100,
          questions: [
            Question(
              questionText: 'What command creates and switches to a new branch?',
              options: ['git branch new', 'git checkout -b', 'git create branch', 'git switch new'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is a merge conflict?',
              options: [
                'When git crashes',
                'When you push to the wrong repository',
                'When changes on different branches clash and cannot be auto-merged',
                'When you forget your git password'
              ],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What does `git rebase` do?',
              options: [
                'Deletes the base branch',
                'Moves or combines a sequence of commits to a new base commit',
                'Undoes the last commit',
                'Pushes all branches'
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'How do you list all local branches?',
              options: ['git ls-branch', 'git show branches', 'git branch', 'git list'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is the default main branch name in modern Git?',
              options: ['master', 'main', 'trunk', 'root'],
              correctAnswerIndex: 1,
            ),
          ],
        ),
        const Challenge(
          id: 'cpp_hard_01',
          title: 'Advanced C++ OOP',
          topic: 'C++ OOP',
          difficulty: 'Hard',
          xpReward: 200,
          questions: [
            Question(
              questionText: 'What is a pure virtual function?',
              options: [
                'A function with no return type',
                'A function defined as virtual void func() = 0;',
                'A function that only returns 0',
                'A function with no arguments'
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is an abstract class in C++?',
              options: [
                'A class with no data members',
                'A class with at least one pure virtual function',
                'A class declared with the `abstract` keyword',
                'A class with private constructors'
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What is a destructor in C++?',
              options: [
                'Method called when object goes out of scope',
                'Method used to delete files',
                'Function to terminate the program',
                'A keyword to override methods'
              ],
              correctAnswerIndex: 0,
            ),
            Question(
              questionText: 'Which concept avoids "diamond problem" in multiple inheritance?',
              options: ['Templates', 'Virtual inheritance', 'Abstract classes', 'Friend functions'],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'What does a `friend` function bypass?',
              options: ['Syntax errors', 'Access specifiers (private/protected)', 'Compiler warnings', 'Memory limits'],
              correctAnswerIndex: 1,
            ),
          ],
        ),
        const Challenge(
          id: 'sec_hard_01',
          title: 'Cryptography',
          topic: 'InfoSec',
          difficulty: 'Hard',
          xpReward: 200,
          questions: [
            Question(
              questionText: 'What is symmetric encryption?',
              options: [
                'Uses a public and private key pair',
                'Uses the same key for encryption and decryption',
                'Encrypts only half the data',
                'Does not use a key'
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which algorithm is an example of asymmetric encryption?',
              options: ['AES', 'DES', 'RSA', 'MD5'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is the main purpose of a hashing function?',
              options: [
                'To compress files',
                'To verify data integrity',
                'To encrypt passwords for decryption later',
                'To generate IP addresses'
              ],
              correctAnswerIndex: 1,
            ),
            Question(
              questionText: 'Which of the following is considered cryptographically broken?',
              options: ['SHA-256', 'AES-256', 'MD5', 'RSA-2048'],
              correctAnswerIndex: 2,
            ),
            Question(
              questionText: 'What is a salt in cryptography?',
              options: [
                'A weak encryption key',
                'Random data added to a password before hashing',
                'A way to decrypt a hash',
                'A type of symmetric cipher'
              ],
              correctAnswerIndex: 1,
            ),
          ],
        ),
      ];
}
