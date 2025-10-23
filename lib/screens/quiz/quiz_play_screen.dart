import 'package:flutter/material.dart';
import 'package:spah_generator/components/SmoothPress.dart';
import '../../utils/fsrs.dart';

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
  late FSRSCardManager fsrsManager;
  List<Map<String, dynamic>> _currentSessionQuestions = [];

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Berapa jumlah kaki kucing?',
      'options': ['2 kaki', '4 kaki', '6 kaki', '8 kaki'],
      'correctAnswer': '4 kaki',
      'image': '🐱',
      'id': 'question_1',
    },
    {
      'question': 'Apa warna langit di siang hari?',
      'options': ['Merah', 'Biru', 'Hijau', 'Kuning'],
      'correctAnswer': 'Biru',
      'image': '☁️',
      'id': 'question_2',
    },
    {
      'question': 'Manakah yang bukan buah-buahan?',
      'options': ['Apel', 'Wortel', 'Jeruk', 'Mangga'],
      'correctAnswer': 'Wortel',
      'image': '🥕',
      'id': 'question_3',
    },
    {
      'question': 'Berapa hasil dari 5 + 3?',
      'options': ['6', '7', '8', '9'],
      'correctAnswer': '8',
      'image': '🔢',
      'id': 'question_4',
    },
    {
      'question': 'Di mana ikan hidup?',
      'options': ['Darat', 'Udara', 'Air', 'Gunung'],
      'correctAnswer': 'Air',
      'image': '🐟',
      'id': 'question_5',
    },
    {
      'question': 'Apa yang digunakan untuk menulis?',
      'options': ['Sendok', 'Pensil', 'Piring', 'Gelas'],
      'correctAnswer': 'Pensil',
      'image': '✏️',
      'id': 'question_6',
    },
    {
      'question': 'Manakah yang merupakan warna pelangi?',
      'options': ['Coklat', 'Abu-abu', 'Merah', 'Hitam'],
      'correctAnswer': 'Merah',
      'image': '🌈',
      'id': 'question_7',
    },
    {
      'question': 'Kapan waktu untuk tidur?',
      'options': ['Pagi', 'Siang', 'Sore', 'Malam'],
      'correctAnswer': 'Malam',
      'image': '🌙',
      'id': 'question_8',
    },
    {
      'question': 'Apa yang dipakai saat hujan?',
      'options': ['Payung', 'Sendal', 'Topi', 'Kacamata'],
      'correctAnswer': 'Payung',
      'image': '☔',
      'id': 'question_9',
    },
    {
      'question': 'Siapa yang mengajar di sekolah?',
      'options': ['Dokter', 'Polisi', 'Guru', 'Pilot'],
      'correctAnswer': 'Guru',
      'image': '👩‍🏫',
      'id': 'question_10',
    },
  ];
  @override
  void initState() {
    super.initState();
    _initializeFSRS();
    _currentSessionQuestions = _getDueQuestions();
  }

  void _initializeFSRS() {
    fsrsManager = FSRSCardManager();

    for (var question in _questions) {
      if (fsrsManager.getCard(question['id']) == null) {
        final newCard = fsrsManager.fsrs.createCard();
        fsrsManager.updateCard(question['id'], newCard);
      }
    }
  }

  FSRSPerformance _getPerformanceRating(
    bool isCorrect,
    int responseTimeSeconds,
    int attempts,
  ) {
    if (!isCorrect) {
      return FSRSPerformance.again;
    }

    if (responseTimeSeconds < 3) {
      return FSRSPerformance.easy;
    } else if (responseTimeSeconds < 8) {
      return FSRSPerformance.good;
    } else {
      return FSRSPerformance.hard;
    }
  }

  List<Map<String, dynamic>> _getDueQuestions() {
    final dueQuestionIds = fsrsManager.getDueCards();

    final dueQuestions = _questions
        .where((question) => dueQuestionIds.contains(question['id']))
        .toList();

    dueQuestions.sort((a, b) {
      final masteryA = fsrsManager.getMasteryLevel(a['id']);
      final masteryB = fsrsManager.getMasteryLevel(b['id']);
      return masteryA.compareTo(masteryB);
    });

    // Jika tidak ada soal yang due, kembalikan semua soal
    if (dueQuestions.isEmpty) {
      final allQuestions = List<Map<String, dynamic>>.from(_questions);
      allQuestions.sort((a, b) {
        final masteryA = fsrsManager.getMasteryLevel(a['id']);
        final masteryB = fsrsManager.getMasteryLevel(b['id']);
        return masteryA.compareTo(masteryB);
      });

      // Menghapus baris .take(3) agar semua soal ditampilkan
      return allQuestions;
    }

    return dueQuestions;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= _currentSessionQuestions.length) {
      return _buildCompletionScreen();
    }

    var currentQuestion = _currentSessionQuestions[_currentQuestionIndex];

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

            Positioned(
              top: 16,
              right: 16,
              child: _buildFSRSProgress(currentQuestion['id']),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pertanyaan ${_currentQuestionIndex + 1}/${_currentSessionQuestions.length}',
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
                                value:
                                    (_currentQuestionIndex + 1) /
                                    _currentSessionQuestions.length,
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
                          child: Column(
                            children: [
                              Text(
                                currentQuestion['question'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D5A7E),
                                  fontFamily: 'ComicNeue',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              _buildCardInfo(currentQuestion['id']),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),
                        ...(currentQuestion['options'] as List<String>)
                            .map(
                              (option) => _buildOptionButton(
                                option,
                                currentQuestion['correctAnswer'],
                                currentQuestion['id'],
                                currentQuestion['options'] as List<String>,
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showResult) _buildResultOverlay(currentQuestion['id']),
          ],
        ),
      ),
    );
  }

  Widget _buildFSRSProgress(String questionId) {
    final card = fsrsManager.getCard(questionId);
    if (card == null) return SizedBox();

    final daysUntilDue = card.dueDate.difference(DateTime.now()).inDays;
    final masteryLevel = fsrsManager.getMasteryLevel(questionId);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMasteryIndicator(masteryLevel),
          SizedBox(height: 4),
          Text(
            daysUntilDue <= 0 ? 'Sekarang' : '$daysUntilDue hari',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _getDueColor(daysUntilDue),
              fontFamily: 'ComicNeue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryIndicator(double mastery) {
    Color color;
    String level;

    if (mastery < 0.3) {
      color = Color(0xFFFE6D73);
      level = 'Baru';
    } else if (mastery < 0.7) {
      color = Color(0xFFFED766);
      level = 'Sedang';
    } else {
      color = Color(0xFF4ECDC4);
      level = 'Mahir';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          level,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getDueColor(int daysUntilDue) {
    if (daysUntilDue <= 0) return Color(0xFFFE6D73);
    if (daysUntilDue <= 2) return Color(0xFFFED766);
    return Color(0xFF4ECDC4);
  }

  Widget _buildCardInfo(String questionId) {
    final card = fsrsManager.getCard(questionId);
    if (card == null) return SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildInfoChip(
          'Stability: ${card.stability.toStringAsFixed(1)}',
          Icons.timeline_rounded,
          Color(0xFF4ECDC4),
        ),
        SizedBox(width: 8),
        _buildInfoChip(
          'Difficulty: ${card.difficulty.toStringAsFixed(1)}',
          Icons.school_rounded,
          Color(0xFFFE6D73),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    String option,
    String correctAnswer,
    String questionId,
    List<String> options,
  ) {
    bool isSelected = _selectedAnswer == option;
    bool isCorrect = option == correctAnswer;

    Color backgroundColor = Colors.white;
    Color borderColor = Color(0xFF4ECDC4).withOpacity(0.3);
    Color textColor = Color(0xFF2D5A7E);

    if (_showResult) {
      if (isSelected) {
        backgroundColor = isCorrect
            ? Color(0xFF4ECDC4).withOpacity(0.2)
            : Color(0xFFFE6D73).withOpacity(0.2);
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
        onPressed: _showResult
            ? () {}
            : () => _selectAnswer(option, correctAnswer, questionId),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 2),
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
                  border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + (options.indexOf(option))),
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

  Widget _buildResultOverlay(String questionId) {
    final card = fsrsManager.getCard(questionId);
    final masteryLevel = fsrsManager.getMasteryLevel(questionId);

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
                    : 'Jawaban yang benar: ${_getQuestionById(questionId)['correctAnswer']}',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),

              if (card != null) ...[
                SizedBox(height: 20),
                _buildMasteryProgress(masteryLevel),
              ],

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

  Widget _buildMasteryProgress(double mastery) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Tingkat Penguasaan',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2D5A7E),
              fontWeight: FontWeight.w600,
              fontFamily: 'ComicNeue',
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: mastery,
            backgroundColor: Colors.grey[300],
            color: _getMasteryColor(mastery),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          SizedBox(height: 4),
          Text(
            '${(mastery * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMasteryColor(double mastery) {
    if (mastery < 0.3) return Color(0xFFFE6D73);
    if (mastery < 0.7) return Color(0xFFFED766);
    return Color(0xFF4ECDC4);
  }

  Widget _buildCompletionScreen() {
    final dueQuestions = _getDueQuestions();
    final totalMastered = fsrsManager.getMasteredCount();

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
                          dueQuestions.isEmpty
                              ? 'Tidak Ada Review Hari Ini!'
                              : 'Sesi Selesai!',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A7E),
                            fontFamily: 'ComicNeue',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 15),

                        Text(
                          dueQuestions.isEmpty
                              ? 'Semua materi sudah direview. Kembali lagi besok!'
                              : 'Bagus! Kamu telah menyelesaikan sesi latihan hari ini',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontFamily: 'ComicNeue',
                          ),
                          textAlign: TextAlign.center,
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
                                'Progress Pembelajaran',
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
                                'Poin Hari Ini',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                  fontFamily: 'ComicNeue',
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCompletionStat(
                                    'Due Besok',
                                    '${_getTomorrowDueCount()}',
                                  ),
                                  _buildCompletionStat(
                                    'Telah Dikuasai',
                                    '$totalMastered/${_questions.length}',
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCompletionStat(
                                    'Benar',
                                    '${_score ~/ 10}/${_currentSessionQuestions.length}',
                                  ),
                                  _buildCompletionStat(
                                    'Salah',
                                    '${_currentSessionQuestions.length - (_score ~/ 10)}/${_currentSessionQuestions.length}',
                                  ),
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
                                        color: Color(
                                          0xFF4ECDC4,
                                        ).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'LATIH LAGI',
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

  int _getTomorrowDueCount() {
    return fsrsManager.getCardsDueInNextDays(1).length;
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

  void _selectAnswer(
    String selectedAnswer,
    String correctAnswer,
    String questionId,
  ) {
    bool isCorrect = selectedAnswer == correctAnswer;

    int responseTimeSeconds = 5; 
    int attempts = 1;

    FSRSPerformance performance = _getPerformanceRating(
      isCorrect,
      responseTimeSeconds,
      attempts,
    );

    final review = fsrsManager.reviewCard(questionId, performance);

    setState(() {
      _selectedAnswer = selectedAnswer;
      _isCorrect = isCorrect;
      _showResult = true;

      if (_isCorrect) {
        _score += 10;
      }
    });

    print('Question: ${_getQuestionById(questionId)['question']}');
    print('Performance: ${performance.toString()}');
    print('Next due: ${review.card.dueDate}');
    print(
      'Mastery: ${(fsrsManager.getMasteryLevel(questionId) * 100).toStringAsFixed(1)}%',
    );
  }

  Map<String, dynamic> _getQuestionById(String id) {
    return _questions.firstWhere((question) => question['id'] == id);
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
      _currentSessionQuestions = _getDueQuestions();
    });
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Keluar Kuis?',
          style: TextStyle(fontFamily: 'ComicNeue', color: Color(0xFF2D5A7E)),
        ),
        content: Text(
          'Progress kuis akan hilang jika kamu keluar sekarang.',
          style: TextStyle(fontFamily: 'ComicNeue'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
