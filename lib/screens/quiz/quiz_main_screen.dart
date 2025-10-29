import 'package:flutter/material.dart';
import 'package:Eksplorasi/components/SmoothPress.dart';
import 'package:Eksplorasi/screens/quiz/quiz_play_screen.dart';
import 'package:Eksplorasi/utils/quiz_stats_manager.dart';
import 'package:Eksplorasi/models/languages/index.dart';

class QuizMainScreen extends StatefulWidget {
  @override
  _QuizMainScreenState createState() => _QuizMainScreenState();
}

class _QuizMainScreenState extends State<QuizMainScreen> {
  Map<String, dynamic> _quizStats = {
    'totalQuizzes': 0,
    'correctAnswers': 0,
    'totalQuestions': 0,
    'averageScore': 0.0,
    'bestStreak': 0,
    'lastScore': 0,
  };

  bool _isLoading = true;
  String _currentLanguage = 'id';

  @override
  void initState() {
    super.initState();
    _loadQuizStats();
    _initializeLanguage();
  }

  void _initializeLanguage() {
    setState(() {
      _currentLanguage = AppLocalizations.current?.currentLanguageCode ?? 'id';
    });
    print('🌐 Quiz Main Screen language: $_currentLanguage');
  }

  Future<void> _loadQuizStats() async {
    final stats = await QuizStatsManager.getQuizStats();
    setState(() {
      _quizStats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Color(0xFFFE6D73).withOpacity(0.1),
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
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
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
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            Column(
              children: [
                SizedBox(height: 40),
              
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    AppLocalizations.get('quiz_main_screen.title'),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D5A7E),
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
                
                SizedBox(height: 10),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    AppLocalizations.get('quiz_main_screen.subtitle'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      fontFamily: 'ComicNeue',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 30),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SmoothPressButton(
                          onPressed: () {
                            _startQuiz();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: Color(0xFFFE6D73),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFE6D73).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  AppLocalizations.get('quiz_main_screen.start_quiz'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        _buildStatsCard(),
                        SizedBox(height: 20),

                        SmoothPressButton(
                          onPressed: () {
                            _showResetConfirmation();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  AppLocalizations.get('quiz_main_screen.reset_stats'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 30),
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

  Widget _buildStatsCard() {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(40),
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
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFE6D73)),
            ),
            SizedBox(height: 20),
            Text(
              AppLocalizations.get('quiz_main_screen.loading_stats'),
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
        border: Border.all(color: Color(0xFFFE6D73).withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Color(0xFFFE6D73),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                AppLocalizations.get('quiz_main_screen.quiz_stats'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 25),
        
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                AppLocalizations.get('quiz_main_screen.quizzes_completed'),
                _quizStats['totalQuizzes'].toString(),
                Icons.assignment_turned_in_rounded,
                Color(0xFFFE6D73),
              ),
              _buildStatItem(
                AppLocalizations.get('quiz_main_screen.average_score'),
                '${_quizStats['averageScore'].toStringAsFixed(1)}%',
                Icons.star_rounded,
                Color(0xFFFED766),
              ),
            ],
          ),
          
          SizedBox(height: 25),
        
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                AppLocalizations.get('quiz_main_screen.correct_answers'),
                '${_quizStats['correctAnswers']}/${_quizStats['totalQuestions']}',
                Icons.check_circle_rounded,
                Color(0xFF4ECDC4),
              ),
              _buildStatItem(
                AppLocalizations.get('quiz_main_screen.best_streak'),
                _quizStats['bestStreak'].toString(),
                Icons.local_fire_department_rounded,
                Color(0xFFFF6B6B),
              ),
            ],
          ),
          
          SizedBox(height: 25),
          
          _buildStatItem(
            AppLocalizations.get('quiz_main_screen.last_score'),
            '${_quizStats['lastScore']}',
            Icons.history_rounded,
            Color(0xFF2D5A7E),
            isFullWidth: true,
          ),
          
          SizedBox(height: 10),
          
          if (_quizStats['totalQuestions'] > 0) ...[
            SizedBox(height: 10),
            _buildAccuracyProgress(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return isFullWidth
        ? Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: color,
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
                ),
              ],
            ),
          )
        : Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
              SizedBox(height: 4),
              Container(
                width: 100,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontFamily: 'ComicNeue',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          );
  }

  Widget _buildAccuracyProgress() {
    final int correctAnswers = _quizStats['correctAnswers'];
    final int totalQuestions = _quizStats['totalQuestions'];
    final double accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.get('quiz_main_screen.answer_accuracy'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
              Text(
                '${accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _getAccuracyColor(accuracy),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: accuracy / 100,
            backgroundColor: Colors.grey[300],
            color: _getAccuracyColor(accuracy),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$correctAnswers ${AppLocalizations.get('quiz_main_screen.correct_answers_count')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                '${AppLocalizations.get('quiz_main_screen.from_total_questions')} $totalQuestions',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Color(0xFF4ECDC4);
    if (accuracy >= 60) return Color(0xFFFED766);
    return Color(0xFFFE6D73);
  }

  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizPlayScreen()),
    ).then((_) {
      _loadQuizStats();
    });
  }

  void _showResetConfirmation() {
    if (_quizStats['totalQuizzes'] == 0) {
      _showMessage(AppLocalizations.get('quiz_main_screen.no_stats_to_reset'));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.get('quiz_main_screen.reset_confirmation_title'),
          style: TextStyle(
            fontFamily: 'ComicNeue',
            color: Color(0xFF2D5A7E),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          AppLocalizations.get('quiz_main_screen.reset_confirmation_message'),
          style: TextStyle(
            fontFamily: 'ComicNeue',
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.get('quiz_main_screen.cancel'),
              style: TextStyle(
                fontFamily: 'ComicNeue',
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _resetStats();
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.get('quiz_main_screen.reset'),
              style: TextStyle(
                fontFamily: 'ComicNeue',
                color: Color(0xFFFE6D73),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetStats() async {
    await QuizStatsManager.resetStats();
    _loadQuizStats();
    _showMessage(AppLocalizations.get('quiz_main_screen.reset_success'));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'ComicNeue'),
        ),
        backgroundColor: Color(0xFF2D5A7E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLanguage = AppLocalizations.current?.currentLanguageCode ?? 'id';
    if (newLanguage != _currentLanguage) {
      setState(() {
        _currentLanguage = newLanguage;
      });
    }
  }
}