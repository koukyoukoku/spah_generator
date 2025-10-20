import 'package:flutter/material.dart';
import 'package:spah_generator/components/SmoothPress.dart';

class QuizPlayScreen extends StatefulWidget {
  final Map<String, dynamic>? category;

  const QuizPlayScreen({this.category});

  @override
  _QuizPlayScreenState createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showResult = false;
  String? _selectedAnswer;
  bool _isCorrect = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Apa warna apel?',
      'options': ['Merah', 'Biru', 'Hijau', 'Kuning'],
      'correctAnswer': 'Merah',
      'image': '🍎'
    },
    {
      'question': 'Hewan apa yang mengeluarkan suara "meong"?',
      'options': ['Anjing', 'Kucing', 'Sapi', 'Ayam'],
      'correctAnswer': 'Kucing',
      'image': '🐱'
    },
    {
      'question': 'Bentuk apa yang memiliki 4 sisi sama?',
      'options': ['Lingkaran', 'Segitiga', 'Persegi', 'Segilima'],
      'correctAnswer': 'Persegi',
      'image': '⬜'
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= _questions.length) {
      return _buildCompletionScreen();
    }

    var currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Color(0xFFFE6D73).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2D5A7E),
                    size: 24,
                  ),
                  onPressed: () => _showExitConfirmation(),
                ),
              ),
            ),

            Column(
              children: [
                SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pertanyaan ${_currentQuestionIndex + 1}/${_questions.length}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D5A7E),
                                      fontFamily: 'ComicNeue',
                                    ),
                                  ),
                                  Text(
                                    'Skor: $_score',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFE6D73),
                                      fontFamily: 'ComicNeue',
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: (_currentQuestionIndex + 1) / _questions.length,
                                backgroundColor: Colors.grey[300],
                                color: Color(0xFF4ECDC4),
                                borderRadius: BorderRadius.circular(10),
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Color(0xFF4ECDC4),
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              currentQuestion['image'],
                              style: TextStyle(fontSize: 50),
                            ),
                          ),
                        ),

                        SizedBox(height: 30),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            currentQuestion['question'],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D5A7E),
                              fontFamily: 'ComicNeue',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: 30),
                        ...(currentQuestion['options'] as List<String>).map((option) => 
                          _buildOptionButton(option, currentQuestion['correctAnswer'])
                        ).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showResult)
              _buildResultOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer) {
    bool isSelected = _selectedAnswer == option;
    bool isCorrect = option == correctAnswer;
    
    Color backgroundColor = Colors.white;
    Color borderColor = Color(0xFF4ECDC4).withOpacity(0.3);
    Color textColor = Color(0xFF2D5A7E);

    if (_showResult) {
      if (isSelected) {
        backgroundColor = isCorrect ? Color(0xFF4ECDC4).withOpacity(0.2) : Color(0xFFFE6D73).withOpacity(0.2);
        borderColor = isCorrect ? Color(0xFF4ECDC4) : Color(0xFFFE6D73);
        textColor = isCorrect ? Color(0xFF2D5A7E) : Color(0xFF2D5A7E);
      } else if (isCorrect) {
        backgroundColor = Color(0xFF4ECDC4).withOpacity(0.2);
        borderColor = Color(0xFF4ECDC4);
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: SmoothPressButton(
        onPressed: _showResult ? () {} : () => _selectAnswer(option, correctAnswer),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF4ECDC4).withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                      String.fromCharCode(65 + (_questions[_currentQuestionIndex]['options'].indexOf(option) as int)),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'ComicNeue',
                  ),
                ),
              ),
              if (_showResult && isSelected)
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: EdgeInsets.all(30),
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 80,
                color: _isCorrect ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
              ),
              SizedBox(height: 20),
              Text(
                _isCorrect ? 'Benar!' : 'Salah!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _isCorrect ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
                  fontFamily: 'ComicNeue',
                ),
              ),
              SizedBox(height: 10),
              Text(
                _isCorrect 
                  ? 'Kamu mendapatkan 10 poin!'
                  : 'Jawaban yang benar: ${_questions[_currentQuestionIndex]['correctAnswer']}',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              SmoothPressButton(
                onPressed: _nextQuestion,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    color: _isCorrect ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'LANJUT',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Color(0xFFFE6D73).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 15,
                                offset: Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: Color(0xFFFED766),
                              width: 6,
                            ),
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 80,
                            color: Color(0xFFFED766),
                          ),
                        ),

                        SizedBox(height: 30),

                        Text(
                          'Kuis Selesai!',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A7E),
                            fontFamily: 'ComicNeue',
                          ),
                        ),

                        SizedBox(height: 15),

                        Text(
                          'Selamat! Kamu telah menyelesaikan kuis',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontFamily: 'ComicNeue',
                          ),
                        ),

                        SizedBox(height: 40),
                        Container(
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: Color(0xFFFED766).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Skor Akhir',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D5A7E),
                                  fontFamily: 'ComicNeue',
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                '$_score',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFED766),
                                ),
                              ),
                              Text(
                                'Poin',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                  fontFamily: 'ComicNeue',
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCompletionStat('Benar', '${(_score / 10).toInt()}/${_questions.length}'),
                                  _buildCompletionStat('Salah', '${_questions.length - (_score / 10).toInt()}/${_questions.length}'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        Row(
                          children: [
                            Expanded(
                              child: SmoothPressButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Color(0xFF4ECDC4),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'KEMBALI',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF4ECDC4),
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'ComicNeue',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: SmoothPressButton(
                                onPressed: _restartQuiz,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4ECDC4),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF4ECDC4).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'ULANGI',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'ComicNeue',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D5A7E),
            fontFamily: 'ComicNeue',
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontFamily: 'ComicNeue',
          ),
        ),
      ],
    );
  }

  void _selectAnswer(String selectedAnswer, String correctAnswer) {
    setState(() {
      _selectedAnswer = selectedAnswer;
      _isCorrect = selectedAnswer == correctAnswer;
      _showResult = true;
      
      if (_isCorrect) {
        _score += 10;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _showResult = false;
      _selectedAnswer = null;
      _currentQuestionIndex++;
    });
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _showResult = false;
      _selectedAnswer = null;
    });
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Keluar Kuis?',
          style: TextStyle(
            fontFamily: 'ComicNeue',
            color: Color(0xFF2D5A7E),
          ),
        ),
        content: Text(
          'Progress kuis akan hilang jika kamu keluar sekarang.',
          style: TextStyle(
            fontFamily: 'ComicNeue',
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'LANJUTKAN',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                color: Color(0xFF4ECDC4),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'KELUAR',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                color: Color(0xFFFE6D73),
              ),
            ),
          ),
        ],
      ),
    );
  }
}