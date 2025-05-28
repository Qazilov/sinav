import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(MyApp());

class Question {
  final String questionText;
  final Map<String, String> options;
  final String correctAnswer;
  final String unit;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.unit,
  });

  static List<Question> sampleQuestions = [
    Question(
      unit: 'Ünite 1',
      questionText: 'Türkiye\'nin başkenti neresidir?',
      options: {'A': 'İstanbul', 'B': 'Ankara', 'C': 'İzmir', 'D': 'Bursa'},
      correctAnswer: 'B',
    ),
    Question(
      unit: 'Ünite 2',
      questionText: 'En büyük okyanus hangisidir?',
      options: {'A': 'Atlantik', 'B': 'Hint', 'C': 'Arktik', 'D': 'Pasifik'},
      correctAnswer: 'D',
    ),
  ];
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  double fontSize = 16;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false, // DEBUG yazısını kaldırır
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: QuizScreen(
        isDarkMode: isDarkMode,
        fontSize: fontSize,
        onThemeChanged: (val) => setState(() => isDarkMode = val),
        onFontSizeChanged: (val) => setState(() => fontSize = val),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final bool isDarkMode;
  final double fontSize;
  final Function(bool) onThemeChanged;
  final Function(double) onFontSizeChanged;
  final Map<int, String?>? savedAnswers;

  const QuizScreen({
    super.key,
    required this.isDarkMode,
    required this.fontSize,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
    this.savedAnswers,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int questionIndex = 0;
  late Timer _timer;
  int remainingSeconds = 20 * 60;
  late Map<int, String?> selectedAnswers;
  late List<bool> showCorrectList;

  @override
  void initState() {
    super.initState();
    selectedAnswers = widget.savedAnswers ?? {};
    showCorrectList = List.generate(
      Question.sampleQuestions.length,
      (index) => selectedAnswers.containsKey(index),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        _timer.cancel();
        _finishQuiz();
      }
    });
  }

  void _finishQuiz() {
    int correct = 0;
    int wrong = 0;
    int blank = 0;

    for (int i = 0; i < Question.sampleQuestions.length; i++) {
      var q = Question.sampleQuestions[i];
      var answer = selectedAnswers[i];
      if (answer == null) {
        blank++;
      } else if (answer == q.correctAnswer) {
        correct++;
      } else {
        wrong++;
      }
    }

    int net = correct - (wrong ~/ 4);
    int point = net * 5;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          correct: correct,
          wrong: wrong,
          blank: blank,
          point: point < 0 ? 0 : point,
          previousAnswers: selectedAnswers,
          isDarkMode: widget.isDarkMode,
          fontSize: widget.fontSize,
          onThemeChanged: widget.onThemeChanged,
          onFontSizeChanged: widget.onFontSizeChanged,
        ),
      ),
    );
  }

  void selectOption(String key) {
    if (selectedAnswers[questionIndex] != null) return;
    setState(() {
      selectedAnswers[questionIndex] = key;
      showCorrectList[questionIndex] = true;
    });
  }

  void nextQuestion() {
    if (questionIndex < Question.sampleQuestions.length - 1) {
      setState(() => questionIndex++);
    } else {
      _timer.cancel();
      _finishQuiz();
    }
  }

  void previousQuestion() {
    if (questionIndex > 0) {
      setState(() => questionIndex--);
    }
  }

  void openSettings() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ayarlar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Tema:'),
                Switch(value: widget.isDarkMode, onChanged: widget.onThemeChanged),
              ],
            ),
            Row(
              children: [
                Text('Yazı Boyutu:'),
                Expanded(
                  child: Slider(
                    value: widget.fontSize,
                    min: 12,
                    max: 24,
                    divisions: 6,
                    label: widget.fontSize.round().toString(),
                    onChanged: widget.onFontSizeChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Kapat')),
        ],
      ),
    );
  }

  String formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = Question.sampleQuestions[questionIndex];
    final selectedOption = selectedAnswers[questionIndex];
    final showCorrect = showCorrectList[questionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(question.unit),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text(formatTime(remainingSeconds))),
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.lightbulb_outline),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Doğru cevap: ${question.correctAnswer}')),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.questionText,
                style: TextStyle(fontSize: widget.fontSize + 2, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            ...question.options.entries.map((entry) {
              bool isSelected = selectedOption == entry.key;
              bool isCorrect = entry.key == question.correctAnswer;
              Color color = Colors.grey.shade200;

              if (isSelected && !isCorrect) color = Colors.red.shade200;
              if (showCorrect && isCorrect) color = Colors.green.shade200;

              return GestureDetector(
                onTap: () => selectOption(entry.key),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text('${entry.key})', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 10),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: previousQuestion, child: Text('Önceki')),
                IconButton(icon: Icon(Icons.settings), onPressed: openSettings),
                ElevatedButton(
                  onPressed: nextQuestion,
                  child: Text(questionIndex == Question.sampleQuestions.length - 1 ? 'Bitir' : 'Sonraki'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final int correct, wrong, blank, point;
  final Map<int, String?> previousAnswers;
  final bool isDarkMode;
  final double fontSize;
  final Function(bool) onThemeChanged;
  final Function(double) onFontSizeChanged;

  const ResultScreen({
    super.key,
    required this.correct,
    required this.wrong,
    required this.blank,
    required this.point,
    required this.previousAnswers,
    required this.isDarkMode,
    required this.fontSize,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sınav Bitti!')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doğru Sayısı: $correct', style: TextStyle(fontSize: fontSize + 2)),
            Text('Yanlış Sayısı: $wrong', style: TextStyle(fontSize: fontSize + 2)),
            Text('Boş Sayısı: $blank', style: TextStyle(fontSize: fontSize + 2)),
            Text('Puanınız: $point', style: TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.replay),
                  label: Text("Gözden Geçir"),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          isDarkMode: isDarkMode,
                          fontSize: fontSize,
                          onThemeChanged: onThemeChanged,
                          onFontSizeChanged: onFontSizeChanged,
                          savedAnswers: previousAnswers,
                        ),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text("Yeni Sınav"),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          isDarkMode: isDarkMode,
                          fontSize: fontSize,
                          onThemeChanged: onThemeChanged,
                          onFontSizeChanged: onFontSizeChanged,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
