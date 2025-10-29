// utils/quiz_stats_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class QuizStatsManager {
  static const String _totalQuizzesKey = 'total_quizzes';
  static const String _correctAnswersKey = 'correct_answers';
  static const String _totalQuestionsKey = 'total_questions';
  static const String _averageScoreKey = 'average_score';
  static const String _bestStreakKey = 'best_streak';
  static const String _lastScoreKey = 'last_score';
  static const String _currentStreakKey = 'current_streak';
  static const String _lastQuizDateKey = 'last_quiz_date';
  static const String _consecutiveDaysKey = 'consecutive_days';

  static Future<void> updateQuizStats({
    required int score,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final DateTime now = DateTime.now();
      final String today = DateTime(now.year, now.month, now.day).toIso8601String();
      
      final String lastQuizDate = prefs.getString(_lastQuizDateKey) ?? '';
      final bool isNewDay = lastQuizDate != today;
      
      // Get current streak and consecutive days
      int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      int consecutiveDays = prefs.getInt(_consecutiveDaysKey) ?? 0;
      final int currentBestStreak = prefs.getInt(_bestStreakKey) ?? 0;
      
      // Handle consecutive days (for daily login)
      if (isNewDay && lastQuizDate.isNotEmpty) {
        final DateTime lastDate = DateTime.parse(lastQuizDate);
        final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
        
        // Check if last play was yesterday (consecutive day)
        if (lastDate.isAtSameMomentAs(yesterday)) {
          consecutiveDays++;
          await prefs.setInt(_consecutiveDaysKey, consecutiveDays);
          print('📅 Consecutive days: $consecutiveDays');
        } else if (lastDate.isBefore(yesterday)) {
          // Missed one or more days - reset consecutive days
          consecutiveDays = 1;
          await prefs.setInt(_consecutiveDaysKey, consecutiveDays);
          print('💥 Consecutive days reset to: $consecutiveDays');
        }
      } else if (lastQuizDate.isEmpty) {
        // First time playing
        consecutiveDays = 1;
        await prefs.setInt(_consecutiveDaysKey, consecutiveDays);
      }
      
      // Update streaks based on perfect score
      if (correctAnswers == totalQuestions) {
        // Perfect score - increase streak
        currentStreak++;
        await prefs.setInt(_currentStreakKey, currentStreak);
        
        // Update best streak if current streak is better
        if (currentStreak > currentBestStreak) {
          await prefs.setInt(_bestStreakKey, currentStreak);
          print('🏆 New best streak: $currentStreak');
        }
        
        print('🔥 Streak increased to: $currentStreak');
      } else {
        // Not perfect score - reset streak
        if (currentStreak > 0) {
          print('💥 Streak broken! Was: $currentStreak');
        }
        await prefs.setInt(_currentStreakKey, 0);
      }
      
      // Update total quizzes
      final int currentTotalQuizzes = prefs.getInt(_totalQuizzesKey) ?? 0;
      await prefs.setInt(_totalQuizzesKey, currentTotalQuizzes + 1);
      
      // Update correct answers and total questions
      final int currentCorrectAnswers = prefs.getInt(_correctAnswersKey) ?? 0;
      final int currentTotalQuestions = prefs.getInt(_totalQuestionsKey) ?? 0;
      
      await prefs.setInt(_correctAnswersKey, currentCorrectAnswers + correctAnswers);
      await prefs.setInt(_totalQuestionsKey, currentTotalQuestions + totalQuestions);
      
      // Update average score
      final double currentAverage = prefs.getDouble(_averageScoreKey) ?? 0.0;
      final int totalQuizzes = currentTotalQuizzes + 1;
      final double newAverage = totalQuizzes > 0 
          ? ((currentAverage * currentTotalQuizzes) + score) / totalQuizzes 
          : score.toDouble();
      await prefs.setDouble(_averageScoreKey, newAverage);
      
      // Update last quiz date
      await prefs.setString(_lastQuizDateKey, today);
      
      // Update last score
      await prefs.setInt(_lastScoreKey, score);
      
      print('📊 Stats updated - Score: $score, Correct: $correctAnswers/$totalQuestions, Streak: $currentStreak, Consecutive Days: $consecutiveDays');
    } catch (e) {
      print('❌ Error updating stats: $e');
    }
  }

  static Future<Map<String, dynamic>> getQuizStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final int totalQuizzes = prefs.getInt(_totalQuizzesKey) ?? 0;
      final int correctAnswers = prefs.getInt(_correctAnswersKey) ?? 0;
      final int totalQuestions = prefs.getInt(_totalQuestionsKey) ?? 0;
      final double averageScore = prefs.getDouble(_averageScoreKey) ?? 0.0;
      final int bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
      final int lastScore = prefs.getInt(_lastScoreKey) ?? 0;
      final int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      final int consecutiveDays = prefs.getInt(_consecutiveDaysKey) ?? 0;
      final String lastQuizDate = prefs.getString(_lastQuizDateKey) ?? '';

      // Calculate accuracy
      final double accuracy = totalQuestions > 0 
          ? (correctAnswers / totalQuestions) * 100 
          : 0.0;

      return {
        'totalQuizzes': totalQuizzes,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'averageScore': averageScore,
        'bestStreak': bestStreak,
        'lastScore': lastScore,
        'currentStreak': currentStreak,
        'consecutiveDays': consecutiveDays,
        'accuracy': accuracy,
        'lastQuizDate': lastQuizDate,
      };
    } catch (e) {
      print('❌ Error getting stats: $e');
      return {
        'totalQuizzes': 0,
        'correctAnswers': 0,
        'totalQuestions': 0,
        'averageScore': 0.0,
        'bestStreak': 0,
        'lastScore': 0,
        'currentStreak': 0,
        'consecutiveDays': 0,
        'accuracy': 0.0,
        'lastQuizDate': '',
      };
    }
  }

  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.remove(_totalQuizzesKey);
      await prefs.remove(_correctAnswersKey);
      await prefs.remove(_totalQuestionsKey);
      await prefs.remove(_averageScoreKey);
      await prefs.remove(_bestStreakKey);
      await prefs.remove(_lastScoreKey);
      await prefs.remove(_currentStreakKey);
      await prefs.remove(_lastQuizDateKey);
      await prefs.remove(_consecutiveDaysKey);
      print('✅ Stats reset successfully');
    } catch (e) {
      print('❌ Error resetting stats: $e');
    }
  }

  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  static Future<int> getConsecutiveDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_consecutiveDaysKey) ?? 0;
  }

  static Future<bool> hasPlayedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final String lastQuizDate = prefs.getString(_lastQuizDateKey) ?? '';
    if (lastQuizDate.isEmpty) return false;
    
    final DateTime lastDate = DateTime.parse(lastQuizDate);
    final DateTime today = DateTime.now();
    final DateTime todayStart = DateTime(today.year, today.month, today.day);
    
    return lastDate.isAtSameMomentAs(todayStart);
  }

  static Future<bool> isStreakActive() async {
    final prefs = await SharedPreferences.getInstance();
    final int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    return currentStreak > 0;
  }

  // Get streak level for UI display
  static Future<String> getStreakLevel() async {
    final int streak = await getCurrentStreak();
    if (streak >= 10) return 'LEGENDARY';
    if (streak >= 7) return 'MASTER';
    if (streak >= 5) return 'EXPERT';
    if (streak >= 3) return 'ADVANCED';
    if (streak >= 1) return 'BEGINNER';
    return 'NONE';
  }

  // Get bonus points based on streak
  static Future<int> getStreakBonus() async {
    final int streak = await getCurrentStreak();
    if (streak >= 10) return 50;
    if (streak >= 7) return 30;
    if (streak >= 5) return 20;
    if (streak >= 3) return 10;
    return 0;
  }
}