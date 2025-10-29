import 'package:Eksplorasi/utils/quiz_stats_manager.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:Eksplorasi/components/SmoothPress.dart';
import '../../utils/fsrs.dart';
import '../../services/firebase.dart';
import '../../services/tts_service.dart';
import 'package:Eksplorasi/models/languages/index.dart';

enum QuestionType { imageSelection, textSelection, objectGuess }

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
  bool _isLoading = true;
  String _errorMessage = '';

  List<Map<String, dynamic>> _questions = [];
  final Random _random = Random();

  bool _isTTSEnabled = true;
  String _currentLanguage = 'id';

  @override
  void initState() {
    super.initState();
    _initializeFSRS();
    _loadQuestionsFromFirebase();
    TTSService.init();
    _initializeLanguage();
  }

  void _initializeLanguage() {
    setState(() {
      _currentLanguage = AppLocalizations.current?.currentLanguageCode ?? 'id';
    });
    print('🌐 Quiz language initialized: $_currentLanguage');
  }

  void _loadQuestionsFromFirebase() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      FirebaseRealtimeDB firebaseDB = FirebaseRealtimeDB();
      Map<String, dynamic>? objectsData = await firebaseDB.getData('objects');

      print('📊 Data structure from Firebase: ${objectsData?.keys}');
      print('🌐 Current language for quiz: $_currentLanguage');

      if (objectsData != null && objectsData.isNotEmpty) {
        List<Map<String, dynamic>> questions = [];

        objectsData.forEach((uid, objectData) {
          try {
            print('🔍 Processing object $uid');

            if (objectData == null) {
              print('⚠️ Object data is null for UID: $uid');
              return;
            }

            Map<String, dynamic> safeObjectData = _convertToSafeMap(objectData);
            safeObjectData['uid'] = uid;
            Map<String, dynamic>? quizData = _getQuizData(
              safeObjectData,
              _currentLanguage,
            );
            String correctAnswer = _getCorrectAnswer(safeObjectData);
            String displayName = _getDisplayName(safeObjectData);

            print('🎯 Object: $displayName, Correct Answer: $correctAnswer');
            print('📝 Quiz data available: ${quizData != null}');

            QuestionType questionType = _getRandomQuestionType();

            Map<String, dynamic> question = {
              'id': uid,
              'question': _getQuestionText(quizData, questionType, displayName),
              'image': _getImagePath(safeObjectData),
              'correctAnswer': correctAnswer,
              'type': questionType.toString(),
              'questionType': questionType,
              'language': _currentLanguage,
              'category': 'object_recognition',
            };

            List<dynamic> options = _getOptions(
              quizData,
              correctAnswer,
              questionType,
              _currentLanguage,
            );
            question['options'] = options;

            questions.add(question);
            print(
              '✅ Successfully processed ${questionType.toString()} question: $correctAnswer',
            );
          } catch (e) {
            print('❌ Error processing object $uid: $e');
          }
        });

        if (questions.isEmpty) {
          setState(() {
            _errorMessage = _currentLanguage == 'id'
                ? 'Tidak ada pertanyaan yang berhasil diproses'
                : 'No questions were successfully processed';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _questions = questions;
          _initializeFSRSCards();
          _currentSessionQuestions = _getDueQuestions();
          _isLoading = false;
        });

        if (_currentSessionQuestions.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakQuestionAuto(_currentSessionQuestions[0]);
          });
        }

        print(
          '🎉 Loaded ${questions.length} questions from Firebase in $_currentLanguage',
        );
        print('📝 Session questions: ${_currentSessionQuestions.length}');
      } else {
        setState(() {
          _errorMessage = _currentLanguage == 'id'
              ? 'Tidak ada data pertanyaan ditemukan di Firebase'
              : 'No question data found in Firebase';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _currentLanguage == 'id'
            ? 'Error loading questions: $e'
            : 'Error loading questions: $e';
        _isLoading = false;
      });
      print('❌ Critical error in _loadQuestionsFromFirebase: $e');
    }
  }

  Map<String, dynamic>? _getQuizData(
    Map<String, dynamic> objectData,
    String language,
  ) {
    try {
      print('🔍 Looking for quiz data in language: $language');

      if (objectData['quiz'] != null && objectData['quiz'] is Map) {
        final quizData = objectData['quiz'] as Map;
        print('📊 Available quiz languages: ${quizData.keys.toList()}');

        if (quizData[language] != null) {
          print('✅ Found quiz data for language: $language');
          return _convertToSafeMap(quizData[language]);
        }

        if (language == 'id' && quizData['en'] != null) {
          print('🔄 Fallback to English quiz data');
          return _convertToSafeMap(quizData['en']);
        } else if (language == 'en' && quizData['id'] != null) {
          print('🔄 Fallback to Indonesian quiz data');
          return _convertToSafeMap(quizData['id']);
        }

        if (quizData.isNotEmpty) {
          final firstLanguage = quizData.keys.first;
          print('🔄 Using first available language: $firstLanguage');
          return _convertToSafeMap(quizData[firstLanguage]);
        }
      }

      print('❌ No quiz data found for any language');
      return null;
    } catch (e) {
      print('❌ Error getting quiz data for language $language: $e');
      return null;
    }
  }

  QuestionType _getRandomQuestionType() {
    return _random.nextBool()
        ? QuestionType.imageSelection
        : QuestionType.textSelection;
  }

  Map<String, dynamic> _convertToSafeMap(dynamic data) {
    if (data is Map) {
      return data.map<String, dynamic>((key, value) {
        String safeKey = key.toString();
        dynamic safeValue = value;
        if (value is Map) {
          safeValue = _convertToSafeMap(value);
        } else if (value is List) {
          safeValue = value.map((item) {
            if (item is Map) {
              return _convertToSafeMap(item);
            }
            return item;
          }).toList();
        }
        return MapEntry(safeKey, safeValue);
      });
    }
    return {};
  }

  String _getQuestionText(
    Map<String, dynamic>? quizData,
    QuestionType questionType,
    String displayName,
  ) {
    try {
      if (quizData != null && quizData['options_type'] != null) {
        Map<String, dynamic> optionsType = quizData['options_type'];

        switch (questionType) {
          case QuestionType.imageSelection:
            if (optionsType['image_type'] != null &&
                optionsType['image_type'] is Map &&
                optionsType['image_type']['question'] != null) {
              return optionsType['image_type']['question'].toString();
            }
            return _currentLanguage == 'id'
                ? "Pilih gambar $displayName yang benar!"
                : "Select the correct $displayName image!";

          case QuestionType.textSelection:
            if (optionsType['text_type'] != null &&
                optionsType['text_type'] is Map &&
                optionsType['text_type']['question'] != null) {
              return optionsType['text_type']['question'].toString();
            }
            return _currentLanguage == 'id'
                ? "Mana tulisan $displayName yang benar?"
                : "Which is the correct spelling of $displayName?";

          case QuestionType.objectGuess:
          default:
            if (optionsType['text_type'] != null &&
                optionsType['text_type'] is Map &&
                optionsType['text_type']['question'] != null) {
              return optionsType['text_type']['question'].toString();
            }
            return _currentLanguage == 'id'
                ? "Apa nama benda ini?"
                : "What is the name of this object?";
        }
      }
    } catch (e) {
      print('⚠️ Error getting question text: $e');
    }

    switch (questionType) {
      case QuestionType.imageSelection:
        return _currentLanguage == 'id'
            ? "Pilih gambar $displayName yang benar!"
            : "Select the correct $displayName image!";
      case QuestionType.textSelection:
        return _currentLanguage == 'id'
            ? "Mana tulisan $displayName yang benar?"
            : "Which is the correct spelling of $displayName?";
      case QuestionType.objectGuess:
      default:
        return _currentLanguage == 'id'
            ? "Apa nama benda ini?"
            : "What is the name of this object?";
    }
  }

  String _getDisplayName(Map<String, dynamic> objectData) {
    try {
      if (objectData[_currentLanguage] != null) {
        return objectData[_currentLanguage].toString();
      }
      if (objectData['id'] != null) {
        return objectData['id'].toString();
      }
      if (objectData['en'] != null) {
        return objectData['en'].toString();
      }
      if (objectData['uid'] != null) {
        return objectData['uid'].toString();
      }
    } catch (e) {
      print('⚠️ Error getting display name: $e');
    }
    return _currentLanguage == 'id' ? 'Benda' : 'Object';
  }

  String _getImagePath(Map<String, dynamic> objectData) {
    try {
      if (objectData['image'] != null) {
        String imagePath = objectData['image'].toString();
        print('🖼️ Image path for ${objectData['id']}: $imagePath');

        if (!imagePath.startsWith('assets/')) {
          imagePath = 'assets/$imagePath';
          print('🔧 Fixed image path: $imagePath');
        }

        return imagePath;
      }
    } catch (e) {
      print('⚠️ Error getting image path: $e');
    }
    return 'assets/images/default.png';
  }

  String _getCorrectAnswer(Map<String, dynamic> objectData) {
    try {
      if (objectData[_currentLanguage] != null) {
        return objectData[_currentLanguage].toString();
      }
      if (objectData['id'] != null) {
        return objectData['id'].toString();
      }
      if (objectData['uid'] != null) {
        return objectData['uid'].toString();
      }
    } catch (e) {
      print('⚠️ Error getting correct answer: $e');
    }
    return _currentLanguage == 'id' ? 'Benda' : 'Object';
  }

  List<dynamic> _getOptions(
    Map<String, dynamic>? quizData,
    String correctAnswer,
    QuestionType questionType,
    String language,
  ) {
    List<dynamic> options = [];

    try {
      if (quizData != null && quizData['options_type'] != null) {
        Map<String, dynamic> optionsType = quizData['options_type'];

        switch (questionType) {
          case QuestionType.imageSelection:
            if (optionsType['image_type'] != null &&
                optionsType['image_type'] is Map &&
                optionsType['image_type']['answers'] != null &&
                optionsType['image_type']['answers'] is List) {
              List<dynamic> imageAnswers = optionsType['image_type']['answers'];
              for (var option in imageAnswers) {
                if (option is Map) {
                  String imagePath = option['images']?.toString() ?? '';
                  String value = option['value']?.toString() ?? '';

                  if (imagePath.isNotEmpty &&
                      !imagePath.startsWith('assets/')) {
                    imagePath = 'assets/$imagePath';
                  }

                  options.add({
                    'type': 'image',
                    'imagePath': imagePath,
                    'value': value,
                    'displayText': value,
                  });
                }
              }
            }
            break;

          case QuestionType.textSelection:
            if (optionsType['text_type'] != null &&
                optionsType['text_type'] is Map &&
                optionsType['text_type']['answers'] != null &&
                optionsType['text_type']['answers'] is List) {
              List<dynamic> textAnswers = optionsType['text_type']['answers'];
              for (var option in textAnswers) {
                options.add({
                  'type': 'text',
                  'value': option.toString(),
                  'displayText': option.toString(),
                });
              }
            }
            break;

          case QuestionType.objectGuess:
          default:
            if (optionsType['text_type'] != null &&
                optionsType['text_type'] is Map &&
                optionsType['text_type']['answers'] != null &&
                optionsType['text_type']['answers'] is List) {
              List<dynamic> textAnswers = optionsType['text_type']['answers'];
              for (var option in textAnswers) {
                options.add({
                  'type': 'text',
                  'value': option.toString(),
                  'displayText': option.toString(),
                });
              }
            }
            break;
        }
      }
    } catch (e) {
      print('⚠️ Error processing options: $e');
      print('🔍 QuizData structure: ${quizData?.keys}');
      if (quizData?['options_type'] != null) {
        print('🔍 OptionsType structure: ${quizData!['options_type'].keys}');
      }
    }

    if (options.isEmpty) {
      print('🔄 Using fallback options for: $correctAnswer in $language');
      return _getFallbackOptions(correctAnswer, questionType, language);
    }

    bool hasCorrectAnswer = options.any((opt) => opt['value'] == correctAnswer);
    if (!hasCorrectAnswer && options.isNotEmpty) {
      String displayText = correctAnswer;

      options[0] = {
        'type': questionType == QuestionType.imageSelection ? 'image' : 'text',
        'imagePath': questionType == QuestionType.imageSelection
            ? 'images/meja.png'
            : '',
        'value': correctAnswer,
        'displayText': displayText,
      };
      print('🔧 Added correct answer to options: $correctAnswer');
    }

    options.shuffle();
    print(
      '🎯 Generated ${options.length} options for $correctAnswer (type: $questionType, language: $language)',
    );
    return options;
  }

  List<dynamic> _getFallbackOptions(
    String correctAnswer,
    QuestionType questionType,
    String language,
  ) {
    if (language == 'id') {
      switch (questionType) {
        case QuestionType.imageSelection:
          return [
            {
              'type': 'image',
              'imagePath': 'assets/images/meja.png',
              'value': correctAnswer,
              'displayText': correctAnswer,
            },
            {
              'type': 'image',
              'imagePath': 'assets/images/kursi.png',
              'value': 'Kursi',
              'displayText': 'Kursi',
            },
            {
              'type': 'image',
              'imagePath': 'assets/images/lemari.png',
              'value': 'Lemari',
              'displayText': 'Lemari',
            },
            {
              'type': 'image',
              'imagePath': 'assets/images/pintu.png',
              'value': 'Pintu',
              'displayText': 'Pintu',
            },
          ];

        case QuestionType.textSelection:
        case QuestionType.objectGuess:
        default:
          return [
            {
              'type': 'text',
              'value': correctAnswer,
              'displayText': correctAnswer,
            },
            {'type': 'text', 'value': 'Kursi', 'displayText': 'Kursi'},
            {'type': 'text', 'value': 'Meja', 'displayText': 'Meja'},
            {'type': 'text', 'value': 'Pintu', 'displayText': 'Pintu'},
          ];
      }
    } else {
      switch (questionType) {
        case QuestionType.imageSelection:
          return [
            {
              'type': 'image',
              'imagePath': 'assets/images/meja.png',
              'value': correctAnswer,
              'displayText': correctAnswer,
            },
            {
              'type': 'image',
              'imagePath': 'assets/images/kursi.png',
              'value': 'Chair',
              'displayText': 'Chair',
            },
            {
              'type': 'image',
              'imagePath': 'assets/images/lemari.png',
              'value': 'Wardrobe',
              'displayText': 'Wardrobe',
            },
            {
              'type': 'image',
              'imagePath': 'assets/images/pintu.png',
              'value': 'Door',
              'displayText': 'Door',
            },
          ];

        case QuestionType.textSelection:
        case QuestionType.objectGuess:
        default:
          return [
            {
              'type': 'text',
              'value': correctAnswer,
              'displayText': correctAnswer,
            },
            {'type': 'text', 'value': 'Chair', 'displayText': 'Chair'},
            {'type': 'text', 'value': 'Table', 'displayText': 'Table'},
            {'type': 'text', 'value': 'Door', 'displayText': 'Door'},
          ];
      }
    }
  }

  void _initializeFSRS() {
    fsrsManager = FSRSCardManager();
  }

  void _initializeFSRSCards() {
    for (var question in _questions) {
      if (fsrsManager.getCard(question['id']) == null) {
        final newCard = fsrsManager.fsrs.createCard();
        fsrsManager.updateCard(question['id'], newCard);
        print('🃏 Initialized FSRS card for: ${question['id']}');
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
    } else if (responseTimeSeconds < 15) {
      return FSRSPerformance.hard;
    } else {
      return FSRSPerformance.hard;
    }
  }

  List<Map<String, dynamic>> _getDueQuestions() {
    if (_questions.isEmpty) return [];

    final dueQuestionIds = fsrsManager.getDueCards();
    print('📅 Due questions: ${dueQuestionIds.length}');

    final dueQuestions = _questions
        .where((question) => dueQuestionIds.contains(question['id']))
        .toList();

    dueQuestions.sort((a, b) {
      final masteryA = fsrsManager.getMasteryLevel(a['id']);
      final masteryB = fsrsManager.getMasteryLevel(b['id']);

      if (masteryA == masteryB) {
        return a['id'].compareTo(b['id']);
      }
      return masteryA.compareTo(masteryB);
    });

    if (dueQuestions.isEmpty) {
      print('🎯 No due questions, creating mixed session');
      final allQuestions = List<Map<String, dynamic>>.from(_questions);

      allQuestions.sort((a, b) {
        final masteryA = fsrsManager.getMasteryLevel(a['id']);
        final masteryB = fsrsManager.getMasteryLevel(b['id']);
        return masteryA.compareTo(masteryB);
      });

      final sessionQuestions = allQuestions.take(5).toList();
      print(
        '🔄 Created mixed session with ${sessionQuestions.length} questions',
      );
      return sessionQuestions;
    }

    print('✅ Returning ${dueQuestions.length} due questions');
    return dueQuestions;
  }

  Widget _buildStreakIndicator(int currentStreak, int bestStreak) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: _getStreakColor(currentStreak), width: 3),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                color: _getStreakColor(currentStreak),
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Streak',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '$currentStreak',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: _getStreakColor(currentStreak),
            ),
          ),
          Text(
            'Hari Berturut-turut',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontFamily: 'ComicNeue',
            ),
          ),
          if (bestStreak > 0) ...[
            SizedBox(height: 8),
            Text(
              'Terbaik: $bestStreak',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStreakColor(int streak) {
    if (streak >= 7) return Color(0xFFFF6B6B);
    if (streak >= 3) return Color(0xFFFFA726);
    return Color(0xFF4ECDC4);
  }

  Widget _buildPerfectScoreReward() {
    final int correctAnswers = _score ~/ 10;
    final int totalQuestions = _currentSessionQuestions.length;

    if (correctAnswers == totalQuestions) {
      return Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA726)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
            SizedBox(width: 6),
            Text(
              'SEMPURNA! +${totalQuestions * 5} Poin Bonus',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLanguage = AppLocalizations.current?.currentLanguageCode ?? 'id';
    if (newLanguage != _currentLanguage) {
      print('🌐 Language changed from $_currentLanguage to $newLanguage');
      setState(() {
        _currentLanguage = newLanguage;
      });
      _loadQuestionsFromFirebase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorScreen();
    }

    if (_currentQuestionIndex >= _currentSessionQuestions.length) {
      return _buildCompletionScreen();
    }

    var currentQuestion = _currentSessionQuestions[_currentQuestionIndex];
    QuestionType currentQuestionType = currentQuestion['questionType'];

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

                        if (currentQuestionType !=
                            QuestionType.imageSelection) ...[
                          Column(
                            children: [
                              _buildQuestionImage(
                                currentQuestion['image'],
                                currentQuestion['correctAnswer'],
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ],
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
                              Row(
                                children: [
                                  Expanded(
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
                                  SizedBox(width: 10),
                                  SmoothPressButton(
                                    onPressed: () =>
                                        _speakQuestion(currentQuestion),
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF4ECDC4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.volume_up_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              _buildCardInfo(currentQuestion['id']),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        _buildOptionsGrid(currentQuestion),
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

  Widget _buildOptionsGrid(Map<String, dynamic> currentQuestion) {
    List<dynamic> options = currentQuestion['options'];
    String correctAnswer = currentQuestion['correctAnswer'];
    String questionId = currentQuestion['id'];

    bool allImages = options.every((opt) => opt['type'] == 'image');
    double gridHeight = allImages ? 300 : 320;

    return Container(
      height: gridHeight,
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          return _buildGridOptionItem(
            options[index],
            correctAnswer,
            questionId,
            index,
          );
        },
      ),
    );
  }

  Widget _buildGridOptionItem(
    dynamic option,
    String correctAnswer,
    String questionId,
    int optionIndex,
  ) {
    bool isSelected = _selectedAnswer == option['value'];
    bool isCorrect = option['value'] == correctAnswer;

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

    return SmoothPressButton(
      onPressed: _showResult
          ? () {}
          : () => _selectAnswer(option['value'], correctAnswer, questionId),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _buildGridOptionContent(option),
              ),
            ),

            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + optionIndex),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            if (_showResult && isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOptionContent(dynamic option) {
    if (option['type'] == 'image') {
      return _buildGridImageOption(option);
    } else {
      return _buildGridTextOption(option);
    }
  }

  Widget _buildGridImageOption(Map<String, dynamic> option) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _loadOptionImageWidget(option['imagePath'], option['value']),
      ),
    );
  }

  Widget _buildGridTextOption(Map<String, dynamic> option) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        option['displayText'],
        style: TextStyle(
          fontSize: 18,
          color: Color(0xFF2D5A7E),
          fontWeight: FontWeight.w600,
          fontFamily: 'ComicNeue',
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildQuestionImage(String imagePath, String objectName) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Color(0xFF4ECDC4), width: 4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _loadImageWidget(imagePath, objectName),
      ),
    );
  }

  Widget _loadImageWidget(String imagePath, String objectName) {
    print('🖼️ Attempting to load image: $imagePath');

    try {
      return Image.asset(
        imagePath,
        width: 140,
        height: 140,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading asset image: $imagePath - $error');
          return _buildFallbackImage(objectName);
        },
      );
    } catch (e) {
      print('❌ Exception loading asset image: $imagePath - $e');
      return _buildFallbackImage(objectName);
    }
  }

  Widget _buildFallbackImage(String objectName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForObject(objectName),
            size: 60,
            color: Color(0xFF4ECDC4),
          ),
          SizedBox(height: 8),
          Text(
            objectName,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2D5A7E),
              fontWeight: FontWeight.w600,
              fontFamily: 'ComicNeue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadOptionImageWidget(String imagePath, String objectName) {
    print('🖼️ Loading option image: $imagePath');

    try {
      return Image.asset(
        imagePath,
        width: 86,
        height: 86,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading option image: $imagePath - $error');
          return _buildFallbackOptionImage(objectName);
        },
      );
    } catch (e) {
      print('❌ Exception loading option image: $imagePath - $e');
      return _buildFallbackOptionImage(objectName);
    }
  }

  Widget _buildFallbackOptionImage(String objectName) {
    return Center(
      child: Icon(
        _getIconForObject(objectName),
        size: 40,
        color: Color(0xFF4ECDC4),
      ),
    );
  }

  IconData _getIconForObject(String objectName) {
    switch (objectName.toLowerCase()) {
      case 'meja':
      case 'table':
        return Icons.table_chart_rounded;
      case 'kursi':
      case 'chair':
        return Icons.chair_rounded;
      case 'lemari':
      case 'wardrobe':
        return Icons.weekend_rounded;
      case 'pintu':
      case 'door':
        return Icons.door_back_door_rounded;
      case 'buku':
      case 'book':
        return Icons.book_rounded;
      case 'pensil':
      case 'pencil':
        return Icons.edit_rounded;
      case 'rumah':
      case 'house':
        return Icons.house_rounded;
      case 'pohon':
      case 'tree':
        return Icons.park_rounded;
      case 'tas':
      case 'bag':
        return Icons.work_rounded;
      case 'ponsel':
      case 'phone':
        return Icons.phone_iphone_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ),
            SizedBox(height: 20),
            Text(
              'Memuat pertanyaan...',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF2D5A7E),
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Color(0xFFFE6D73),
              ),
              SizedBox(height: 20),
              Text(
                'Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
              SizedBox(height: 10),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              SmoothPressButton(
                onPressed: _loadQuestionsFromFirebase,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'COBA LAGI',
                    style: TextStyle(
                      fontSize: 16,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMasteryIndicator(masteryLevel),
          if (daysUntilDue < 0) ...{
            SizedBox(width: 7),
            Text(
              '$daysUntilDue hari',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _getDueColor(daysUntilDue),
                fontFamily: 'ComicNeue',
              ),
            ),
          },
        ],
      ),
    );
  }

  Widget _buildMasteryIndicator(double mastery) {
    Color color;
    String level;

    if (mastery < 0.3) {
      color = Color(0xFFFE6D73);
      level = 'Noob';
    } else if (mastery < 0.7) {
      color = Color(0xFFFED766);
      level = 'Pro';
    } else {
      color = Color(0xFF4ECDC4);
      level = 'Hacker';
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
            fontSize: 12,
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
                _isCorrect
                    ? (_currentLanguage == 'id' ? 'Benar!' : 'Correct!')
                    : (_currentLanguage == 'id' ? 'Salah!' : 'Wrong!'),
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
                    ? (_currentLanguage == 'id'
                          ? 'Kamu mendapatkan 10 poin!'
                          : 'You got 10 points!')
                    : '${_currentLanguage == 'id' ? 'Jawaban yang benar:' : 'Correct answer:'} ${_getQuestionById(questionId)['correctAnswer']}',
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
                    _currentLanguage == 'id' ? 'LANJUT' : 'NEXT',
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

  Widget _buildLoadingCompletionScreen() {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ),
            SizedBox(height: 20),
            Text(
              'Memuat statistik...',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF2D5A7E),
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCompletionScreen(String error) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Color(0xFFFE6D73),
              ),
              SizedBox(height: 20),
              Text(
                'Gagal Memuat Statistik',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
              SizedBox(height: 10),
              Text(
                error,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              SmoothPressButton(
                onPressed: () {
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'COBA LAGI',
                    style: TextStyle(
                      fontSize: 16,
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
    final dueQuestions = _getDueQuestions();
    final totalMastered = fsrsManager.getMasteredCount();
    final int correctAnswers = _score ~/ 10;
    final int totalQuestions = _currentSessionQuestions.length;

    int bonusPoints = 0;
    if (correctAnswers == totalQuestions) {
      bonusPoints = totalQuestions * 5;
    }

    final int totalScore = _score + bonusPoints;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateQuizStats();
    });

    return FutureBuilder<Map<String, dynamic>>(
      future: QuizStatsManager.getQuizStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCompletionScreen();
        }
        if (snapshot.hasError) {
          return _buildErrorCompletionScreen(snapshot.error.toString());
        }

        final stats = snapshot.data!;
        final int currentStreak = stats['currentStreak'] ?? 0;
        final int bestStreak = stats['bestStreak'] ?? 0;
        final int consecutiveDays = stats['consecutiveDays'] ?? 0;

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
                            _buildStreakIndicator(currentStreak, bestStreak),
                            SizedBox(height: 20),
                            _buildPerfectScoreReward(),

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
                                  color: correctAnswers == totalQuestions
                                      ? Color(0xFFFFD700)
                                      : Color(0xFFFED766),
                                  width: 6,
                                ),
                              ),
                              child: Icon(
                                correctAnswers == totalQuestions
                                    ? Icons.emoji_events_rounded
                                    : Icons.celebration_rounded,
                                size: 80,
                                color: correctAnswers == totalQuestions
                                    ? Color(0xFFFFD700)
                                    : Color(0xFFFED766),
                              ),
                            ),

                            SizedBox(height: 30),

                            Text(
                              dueQuestions.isEmpty
                                  ? (_currentLanguage == 'id'
                                        ? 'Tidak Ada Review Hari Ini!'
                                        : 'No Review Today!')
                                  : correctAnswers == totalQuestions
                                  ? (_currentLanguage == 'id'
                                        ? 'SEMPURNA! 🎉'
                                        : 'PERFECT! 🎉')
                                  : (_currentLanguage == 'id'
                                        ? 'Sesi Selesai!'
                                        : 'Session Completed!'),
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
                                  ? (_currentLanguage == 'id'
                                        ? 'Semua materi sudah direview. Kembali lagi besok!'
                                        : 'All materials have been reviewed. Come back tomorrow!')
                                  : correctAnswers == totalQuestions
                                  ? (_currentLanguage == 'id'
                                        ? 'Luar biasa! Kamu menjawab semua pertanyaan dengan benar!'
                                        : 'Amazing! You answered all questions correctly!')
                                  : (_currentLanguage == 'id'
                                        ? 'Bagus! Kamu telah menyelesaikan sesi latihan hari ini'
                                        : 'Good job! You have completed today\'s practice session'),
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
                                  Column(
                                    children: [
                                      Text(
                                        '$totalScore',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFFED766),
                                        ),
                                      ),
                                      if (bonusPoints > 0) ...[
                                        Text(
                                          '$_score + $bonusPoints Bonus',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFFFA726),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        'Total Poin',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF666666),
                                          fontFamily: 'ComicNeue',
                                        ),
                                      ),
                                    ],
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

                                  if (currentStreak > 0) ...[
                                    SizedBox(height: 20),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _getStreakColor(
                                          currentStreak,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStreakColor(
                                            currentStreak,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            color: _getStreakColor(
                                              currentStreak,
                                            ),
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Streak $currentStreak hari berturut-turut!',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _getStreakColor(
                                                currentStreak,
                                              ),
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'ComicNeue',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            SizedBox(height: 30),

                            Row(
                              children: [
                                Expanded(
                                  child: SmoothPressButton(
                                    onPressed: () {
                                      _updateQuizStats();
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
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
                                    onPressed: () {
                                      _updateQuizStats();
                                      _restartQuiz();
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
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
      },
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

  void _updateQuizStats() {
    final int correctAnswers = _score ~/ 10;
    final int totalQuestions = _currentSessionQuestions.length;

    QuizStatsManager.updateQuizStats(
      score: _score,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
    );
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _showResult = false;
      _selectedAnswer = null;
      _currentSessionQuestions = _getDueQuestions();
    });

    if (_currentSessionQuestions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _speakQuestionAuto(_currentSessionQuestions[0]);
      });
    }
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

    if (fsrsManager.getCard(questionId) == null) {
      final newCard = fsrsManager.fsrs.createCard();
      fsrsManager.updateCard(questionId, newCard);
    }

    final review = fsrsManager.reviewCard(questionId, performance);

    setState(() {
      _selectedAnswer = selectedAnswer;
      _isCorrect = isCorrect;
      _showResult = true;

      if (_isCorrect) {
        _score += 10;
      }
    });

    print('📊 Question: ${_getQuestionById(questionId)['question']}');
    print('📈 Performance: ${performance.toString()}');
    print('⏰ Next due: ${review.card.dueDate}');
    print(
      '🎯 Mastery: ${(fsrsManager.getMasteryLevel(questionId) * 100).toStringAsFixed(1)}%',
    );
  }

  Map<String, dynamic> _getQuestionById(String id) {
    try {
      return _questions.firstWhere((question) => question['id'] == id);
    } catch (e) {
      print('❌ Question not found for id: $id');
      return {
        'id': id,
        'question': 'Pertanyaan tidak ditemukan',
        'correctAnswer': 'Benda',
        'options': [],
      };
    }
  }

  void _nextQuestion() {
    setState(() {
      _showResult = false;
      _selectedAnswer = null;
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex < _currentSessionQuestions.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _speakQuestionAuto(_currentSessionQuestions[_currentQuestionIndex]);
      });
    }
  }

  void _speakQuestionAuto(Map<String, dynamic> question) async {
    if (!_isTTSEnabled) return;

    try {
      await Future.delayed(Duration(milliseconds: 500));

      QuestionType questionType =
          question['questionType'] ?? QuestionType.objectGuess;
      String language = question['language'] ?? _currentLanguage;

      await TTSService.setLanguage(language);

      switch (questionType) {
        case QuestionType.imageSelection:
          await TTSService.speak(question['question']);
          break;
        case QuestionType.textSelection:
          await TTSService.speak(question['question']);
          break;
        case QuestionType.objectGuess:
        default:
          await TTSService.speak(question['question']);
          break;
      }
    } catch (e) {
      print('❌ Error in auto speak question: $e');
    }
  }

  void _speakQuestionManual(Map<String, dynamic> question) async {
    try {
      String language = question['language'] ?? _currentLanguage;
      await TTSService.setLanguage(language);

      QuestionType questionType =
          question['questionType'] ?? QuestionType.objectGuess;

      switch (questionType) {
        case QuestionType.imageSelection:
          await TTSService.speak(question['question']);
          break;
        case QuestionType.textSelection:
          await TTSService.speak(question['question']);
          break;
        case QuestionType.objectGuess:
        default:
          await TTSService.speak(question['question']);
          break;
      }
    } catch (e) {
      print('❌ Error in manual speak question: $e');
    }
  }

  Widget _buildTTSToggleButton() {
    return SmoothPressButton(
      onPressed: () {
        setState(() {
          _isTTSEnabled = !_isTTSEnabled;
        });
        if (!_isTTSEnabled) {
          TTSService.stop();
        }
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isTTSEnabled ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isTTSEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _currentLanguage == 'id' ? 'Keluar Kuis?' : 'Exit Quiz?',
          style: TextStyle(fontFamily: 'ComicNeue', color: Color(0xFF2D5A7E)),
        ),
        content: Text(
          _currentLanguage == 'id'
              ? 'Progress kuis akan hilang jika kamu keluar sekarang.'
              : 'Your quiz progress will be lost if you exit now.',
          style: TextStyle(fontFamily: 'ComicNeue'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _currentLanguage == 'id' ? 'LANJUTKAN' : 'CONTINUE',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                color: Color(0xFF4ECDC4),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _updateQuizStats();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              _currentLanguage == 'id' ? 'KELUAR' : 'EXIT',
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

  void _speakQuestion(Map<String, dynamic> question) async {
    try {
      QuestionType questionType =
          question['questionType'] ?? QuestionType.objectGuess;

      switch (questionType) {
        case QuestionType.imageSelection:
          await TTSService.speak(question['question']);
          break;
        case QuestionType.textSelection:
          await TTSService.speak(question['question']);
          break;
        case QuestionType.objectGuess:
        default:
          await TTSService.speak(question['question']);
          break;
      }
    } catch (e) {
      print('❌ Error speaking question: $e');
    }
  }
}
