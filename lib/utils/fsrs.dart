import 'dart:math';

class FSRS {
  // Default parameters for FSRS algorithm
  static const List<double> defaultParameters = [
    0.4,  // Initial difficulty
    2.0,  // Initial stability
    0.2,  // Difficulty adjustment factor
    1.2,  // Stability increase factor (easy)
    1.0,  // Stability increase factor (good)
    0.8,  // Stability increase factor (hard)
    0.1,  // Stability decrease factor (again)
    0.5,  // Maximum difficulty
    2.5,  // Minimum stability
    365,  // Maximum interval in days
  ];

  final List<double> parameters;

  FSRS({List<double>? parameters}) 
      : parameters = parameters ?? defaultParameters;

  // Create a new card with initial state
  FSRSCard createCard() {
    return FSRSCard(
      difficulty: parameters[0],
      stability: parameters[1],
      lastReview: DateTime.now(),
      dueDate: DateTime.now(),
      reviewCount: 0,
      lapseCount: 0,
    );
  }

  // Review a card and update its state based on performance
  FSRSCardReview reviewCard(FSRSCard card, FSRSPerformance performance) {
    final now = DateTime.now();
    final elapsedDays = _getElapsedDays(card.lastReview, now);
    
    double retrievability = _calculateRetrievability(card, elapsedDays);
    
    // Update card state based on performance
    final updatedCard = _updateCardState(card, performance, elapsedDays, retrievability);
    
    // Create review log
    final reviewLog = FSRSCardReview(
      card: updatedCard,
      performance: performance,
      retrievability: retrievability,
      reviewDate: now,
      elapsedDays: elapsedDays,
    );
    
    return reviewLog;
  }

  // Calculate next due date based on card state
  DateTime calculateNextDueDate(FSRSCard card) {
    final interval = _calculateOptimalInterval(card);
    return card.lastReview.add(Duration(days: interval));
  }

  // Calculate retrievability probability (0-1)
  double calculateRetrievability(FSRSCard card) {
    final elapsedDays = _getElapsedDays(card.lastReview, DateTime.now());
    return _calculateRetrievability(card, elapsedDays);
  }

  // Private helper methods
  double _calculateRetrievability(FSRSCard card, double elapsedDays) {
    // Exponential forgetting curve
    return exp(-elapsedDays / card.stability);
  }

  int _calculateOptimalInterval(FSRSCard card) {
    // Simple interval calculation based on stability and difficulty
    double baseInterval = card.stability * (1 - card.difficulty);
    baseInterval = max(1.0, baseInterval); // Minimum 1 day
    baseInterval = min(baseInterval, parameters[9]); // Maximum interval
    
    // Add some fuzzing to avoid pattern recognition
    final fuzz = Random().nextDouble() * 0.1 + 0.95; // 95-105% variation
    
    return (baseInterval * fuzz).round();
  }

  FSRSCard _updateCardState(
    FSRSCard card, 
    FSRSPerformance performance, 
    double elapsedDays, 
    double retrievability
  ) {
    double newDifficulty = card.difficulty;
    double newStability = card.stability;
    
    switch (performance) {
      case FSRSPerformance.again:
        // Failed recall - increase difficulty, decrease stability
        newDifficulty = min(
          parameters[7], 
          card.difficulty + parameters[2]
        );
        newStability = max(
          parameters[8], 
          card.stability * parameters[6]
        );
        break;
        
      case FSRSPerformance.hard:
        // Hard recall - slight difficulty increase, small stability increase
        newDifficulty = min(
          parameters[7], 
          card.difficulty + parameters[2] * 0.5
        );
        newStability = card.stability * parameters[5];
        break;
        
      case FSRSPerformance.good:
        // Good recall - maintain difficulty, good stability increase
        newDifficulty = card.difficulty;
        newStability = card.stability * parameters[4];
        break;
        
      case FSRSPerformance.easy:
        // Easy recall - decrease difficulty, large stability increase
        newDifficulty = max(
          0.1, 
          card.difficulty - parameters[2]
        );
        newStability = card.stability * parameters[3];
        break;
    }
    
    // Calculate next interval
    final optimalInterval = _calculateOptimalInterval(FSRSCard(
      difficulty: newDifficulty,
      stability: newStability,
      lastReview: card.lastReview,
      dueDate: card.dueDate,
      reviewCount: card.reviewCount + 1,
      lapseCount: performance == FSRSPerformance.again 
          ? card.lapseCount + 1 
          : card.lapseCount,
    ));
    
    return FSRSCard(
      difficulty: newDifficulty,
      stability: newStability,
      lastReview: DateTime.now(),
      dueDate: DateTime.now().add(Duration(days: optimalInterval)),
      reviewCount: card.reviewCount + 1,
      lapseCount: performance == FSRSPerformance.again 
          ? card.lapseCount + 1 
          : card.lapseCount,
    );
  }

  double _getElapsedDays(DateTime from, DateTime to) {
    return to.difference(from).inSeconds / 86400.0; // Convert seconds to days
  }
}

// Card state class
class FSRSCard {
  final double difficulty; // 0.1 (easy) to 0.5 (hard)
  final double stability; // Days until next review
  final DateTime lastReview;
  final DateTime dueDate;
  final int reviewCount;
  final int lapseCount;

  FSRSCard({
    required this.difficulty,
    required this.stability,
    required this.lastReview,
    required this.dueDate,
    required this.reviewCount,
    required this.lapseCount,
  });

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'difficulty': difficulty,
      'stability': stability,
      'lastReview': lastReview.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'reviewCount': reviewCount,
      'lapseCount': lapseCount,
    };
  }

  // Create from map for deserialization
  factory FSRSCard.fromMap(Map<String, dynamic> map) {
    return FSRSCard(
      difficulty: map['difficulty'] ?? 0.4,
      stability: map['stability'] ?? 2.0,
      lastReview: DateTime.fromMillisecondsSinceEpoch(map['lastReview']),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      reviewCount: map['reviewCount'] ?? 0,
      lapseCount: map['lapseCount'] ?? 0,
    );
  }

  FSRSCard copyWith({
    double? difficulty,
    double? stability,
    DateTime? lastReview,
    DateTime? dueDate,
    int? reviewCount,
    int? lapseCount,
  }) {
    return FSRSCard(
      difficulty: difficulty ?? this.difficulty,
      stability: stability ?? this.stability,
      lastReview: lastReview ?? this.lastReview,
      dueDate: dueDate ?? this.dueDate,
      reviewCount: reviewCount ?? this.reviewCount,
      lapseCount: lapseCount ?? this.lapseCount,
    );
  }
}

// Performance rating enum
enum FSRSPerformance {
  again, // Complete forget
  hard,  // Remembered with difficulty
  good,  // Remembered after hesitation
  easy,  // Easy recall
}

// Review result class
class FSRSCardReview {
  final FSRSCard card;
  final FSRSPerformance performance;
  final double retrievability;
  final DateTime reviewDate;
  final double elapsedDays;

  FSRSCardReview({
    required this.card,
    required this.performance,
    required this.retrievability,
    required this.reviewDate,
    required this.elapsedDays,
  });
}

// Helper class to manage multiple cards
class FSRSCardManager {
  final FSRS fsrs;
  final Map<String, FSRSCard> _cards = {};

  FSRSCardManager({FSRS? fsrs}) : fsrs = fsrs ?? FSRS();

  // Add or update a card
  void updateCard(String id, FSRSCard card) {
    _cards[id] = card;
  }

  // Get a card by ID
  FSRSCard? getCard(String id) {
    return _cards[id];
  }

  // Review a card and update its state
  FSRSCardReview reviewCard(String id, FSRSPerformance performance) {
    var card = _cards[id] ?? fsrs.createCard();
    final review = fsrs.reviewCard(card, performance);
    _cards[id] = review.card;
    return review;
  }

  // Get all due cards
  List<String> getDueCards() {
    final now = DateTime.now();
    return _cards.entries
        .where((entry) => entry.value.dueDate.isBefore(now) || 
                         entry.value.dueDate.isAtSameMomentAs(now))
        .map((entry) => entry.key)
        .toList();
  }

  // Get cards due within next N days
  List<String> getCardsDueInNextDays(int days) {
    final cutoff = DateTime.now().add(Duration(days: days));
    return _cards.entries
        .where((entry) => entry.value.dueDate.isBefore(cutoff))
        .map((entry) => entry.key)
        .toList();
  }

  // Get mastery level of a card (0-1)
  double getMasteryLevel(String id) {
    final card = _cards[id];
    if (card == null) return 0.0;
    
    // Mastery based on stability and difficulty
    final stabilityScore = min(1.0, card.stability / 30.0); // Max 30 days stability
    final difficultyScore = 1.0 - card.difficulty; // Lower difficulty = better mastery
    
    return (stabilityScore * 0.6 + difficultyScore * 0.4);
  }

  // Get total mastered cards (mastery > 0.7)
  int getMasteredCount() {
    return _cards.values.where((card) => getMasteryLevel(_cards.keys.firstWhere(
      (key) => _cards[key] == card)) > 0.7).length;
  }

  // Serialize all cards to map
  Map<String, dynamic> toMap() {
    return {
      'cards': _cards.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  // Deserialize from map
  factory FSRSCardManager.fromMap(Map<String, dynamic> map, {FSRS? fsrs}) {
    final manager = FSRSCardManager(fsrs: fsrs);
    final cardsMap = map['cards'] as Map<String, dynamic>? ?? {};
    
    cardsMap.forEach((key, value) {
      manager._cards[key] = FSRSCard.fromMap(value);
    });
    
    return manager;
  }
}