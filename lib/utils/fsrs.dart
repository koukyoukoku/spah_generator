import 'dart:math';

class FSRS {
  // Parameters optimized for FSRS algorithm (based on Anki's implementation)
  static const List<double> defaultParameters = [
    0.4,   // w[0] - initial difficulty
    0.9,   // w[1] - initial stability
    2.3,   // w[2] - difficulty decay
    10.0,  // w[3] - stability gain on successful recall
    5.0,   // w[4] - stability gain on hard recall
    0.2,   // w[5] - difficulty factor on hard
    1.0,   // w[6] - difficulty factor on good
    1.4,   // w[7] - difficulty factor on easy
    0.8,   // w[8] - stability retention on failed recall
    2.0,   // w[9] - minimum stability
    0.3,   // w[10] - maximum difficulty
    1.5,   // w[11] - stability gain factor
  ];

  final List<double> w;
  final Random _random;

  FSRS({List<double>? parameters, Random? random})
      : w = parameters ?? defaultParameters,
        _random = random ?? Random();

  // Create a new card with initial state
  FSRSCard createCard() {
    final now = DateTime.now();
    return FSRSCard(
      difficulty: w[0],
      stability: w[1],
      lastReview: now,
      dueDate: now,
      reviewCount: 0,
      lapseCount: 0,
      elapsedDays: 0,
      scheduledDays: 0,
      state: CardState.newCard,
    );
  }

  // Main review function based on FSRS algorithm
  FSRSCardReview reviewCard(FSRSCard card, FSRSPerformance performance) {
    final now = DateTime.now();
    final double elapsedDays = max(0.1, (now.difference(card.lastReview).inSeconds / 86400)).toDouble();
    
    if (card.state == CardState.newCard || card.reviewCount == 0) {
      return _reviewNewCard(card, performance, now);
    } else {
      return _reviewReviewCard(card, performance, elapsedDays, now);
    }
  }

  FSRSCardReview _reviewNewCard(FSRSCard card, FSRSPerformance performance, DateTime now) {
    double difficulty = _initDifficulty(performance);
    double stability = _initStability(performance);
    
    int nextInterval = _nextInterval(stability, performance);
    DateTime nextDue = now.add(Duration(days: nextInterval));
    
    final updatedCard = card.copyWith(
      difficulty: difficulty,
      stability: stability,
      lastReview: now,
      dueDate: nextDue,
      reviewCount: card.reviewCount + 1,
      lapseCount: performance == FSRSPerformance.again ? card.lapseCount + 1 : card.lapseCount,
      elapsedDays: 0,
      scheduledDays: nextInterval,
      state: performance == FSRSPerformance.again ? CardState.relearning : CardState.learning,
    );
    
    return FSRSCardReview(
      card: updatedCard,
      performance: performance,
      retrievability: 1.0,
      reviewDate: now,
      elapsedDays: 0,
    );
  }

  FSRSCardReview _reviewReviewCard(FSRSCard card, FSRSPerformance performance, double elapsedDays, DateTime now) {
    double retrievability = exp(log(0.9) * elapsedDays / card.stability);
    
    double difficulty = card.difficulty;
    double stability = card.stability;
    
    if (performance == FSRSPerformance.again) {
      // Failed recall
      difficulty = min(w[10], difficulty + w[5]);
      stability = max(w[9], stability * w[8]);
    } else {
      // Successful recall
      difficulty = _nextDifficulty(difficulty, performance);
      stability = _nextStability(stability, difficulty, performance, retrievability);
    }
    
    int nextInterval = _nextInterval(stability, performance);
    DateTime nextDue = now.add(Duration(days: nextInterval));
    
    CardState newState = performance == FSRSPerformance.again ? CardState.relearning : CardState.review;
    
    final updatedCard = card.copyWith(
      difficulty: difficulty.clamp(0.1, w[10]),
      stability: stability.clamp(w[9], 365.0), // Max stability 1 year
      lastReview: now,
      dueDate: nextDue,
      reviewCount: card.reviewCount + 1,
      lapseCount: performance == FSRSPerformance.again ? card.lapseCount + 1 : card.lapseCount,
      elapsedDays: elapsedDays,
      scheduledDays: nextInterval,
      state: newState,
    );
    
    return FSRSCardReview(
      card: updatedCard,
      performance: performance,
      retrievability: retrievability,
      reviewDate: now,
      elapsedDays: elapsedDays,
    );
  }

  double _initDifficulty(FSRSPerformance performance) {
    switch (performance) {
      case FSRSPerformance.again:
        return (w[0] + w[5]).clamp(0.1, w[10]);
      case FSRSPerformance.hard:
        return (w[0] + w[6] * 0.5).clamp(0.1, w[10]);
      case FSRSPerformance.good:
        return w[0];
      case FSRSPerformance.easy:
        return max(0.1, w[0] - w[7]);
    }
  }

  double _initStability(FSRSPerformance performance) {
    switch (performance) {
      case FSRSPerformance.again:
        return w[9];
      case FSRSPerformance.hard:
        return w[1] * w[4];
      case FSRSPerformance.good:
        return w[1] * w[3];
      case FSRSPerformance.easy:
        return w[1] * w[3] * w[11];
    }
  }

  double _nextDifficulty(double currentD, FSRSPerformance performance) {
    switch (performance) {
      case FSRSPerformance.again:
        return (currentD + w[5]).clamp(0.1, w[10]);
      case FSRSPerformance.hard:
        return (currentD + w[6]).clamp(0.1, w[10]);
      case FSRSPerformance.good:
        return currentD;
      case FSRSPerformance.easy:
        return max(0.1, currentD - w[7]);
    }
  }

  double _nextStability(double currentS, double difficulty, FSRSPerformance performance, double retrievability) {
    double hardPenalty = performance == FSRSPerformance.hard ? w[4] : 1.0;
    double easyBonus = performance == FSRSPerformance.easy ? w[11] : 1.0;
    
    double s = currentS * (1 + 
        exp(w[2]) * 
        (11 - difficulty) * 
        pow(currentS, -w[3]) * 
        (exp((1 - retrievability) * w[4]) - 1) * 
        hardPenalty * 
        easyBonus
    );
    
    return s.clamp(w[9], 365.0); // Ensure stability stays within bounds
  }

  int _nextInterval(double stability, FSRSPerformance performance) {
    double interval;
    
    switch (performance) {
      case FSRSPerformance.again:
        return 1; // 1 day for again
      case FSRSPerformance.hard:
        interval = stability * 0.5;
        break;
      case FSRSPerformance.good:
        interval = stability;
        break;
      case FSRSPerformance.easy:
        interval = stability * 1.5;
        break;
    }
    
    // Add some fuzzing to avoid pattern recognition
    final fuzz = 0.95 + _random.nextDouble() * 0.1; // 95-105% variation
    interval = interval * fuzz;
    
    return max(1, interval.round());
  }

  // Calculate retrievability probability (0-1)
  double calculateRetrievability(FSRSCard card) {
    final double elapsedDays = max(0.1, (DateTime.now().difference(card.lastReview).inSeconds / 86400)).toDouble();
    return exp(log(0.9) * elapsedDays / card.stability);
  }

  // Check if card is due for review
  bool isCardDue(FSRSCard card) {
    return DateTime.now().isAfter(card.dueDate) || 
           DateTime.now().isAtSameMomentAs(card.dueDate);
  }

  // Get days until card is due (negative if overdue)
  int getDaysUntilDue(FSRSCard card) {
    return card.dueDate.difference(DateTime.now()).inDays;
  }
}

// Card state enum
enum CardState {
  newCard,
  learning,
  review,
  relearning,
}

// Enhanced Card state class
class FSRSCard {
  final double difficulty; // 0.1 (easy) to 1.0 (hard)
  final double stability; // Days until next review
  final DateTime lastReview;
  final DateTime dueDate;
  final int reviewCount;
  final int lapseCount;
  final double elapsedDays;
  final int scheduledDays;
  final CardState state;

  FSRSCard({
    required this.difficulty,
    required this.stability,
    required this.lastReview,
    required this.dueDate,
    required this.reviewCount,
    required this.lapseCount,
    required this.elapsedDays,
    required this.scheduledDays,
    required this.state,
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
      'elapsedDays': elapsedDays,
      'scheduledDays': scheduledDays,
      'state': state.index,
    };
  }

  // Create from map for deserialization
  factory FSRSCard.fromMap(Map<String, dynamic> map) {
    return FSRSCard(
      difficulty: (map['difficulty'] ?? 0.4).toDouble(),
      stability: (map['stability'] ?? 2.0).toDouble(),
      lastReview: DateTime.fromMillisecondsSinceEpoch(map['lastReview'] ?? DateTime.now().millisecondsSinceEpoch),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? DateTime.now().millisecondsSinceEpoch),
      reviewCount: map['reviewCount'] ?? 0,
      lapseCount: map['lapseCount'] ?? 0,
      elapsedDays: (map['elapsedDays'] ?? 0).toDouble(),
      scheduledDays: map['scheduledDays'] ?? 0,
      state: CardState.values[map['state'] ?? 0],
    );
  }

  FSRSCard copyWith({
    double? difficulty,
    double? stability,
    DateTime? lastReview,
    DateTime? dueDate,
    int? reviewCount,
    int? lapseCount,
    double? elapsedDays,
    int? scheduledDays,
    CardState? state,
  }) {
    return FSRSCard(
      difficulty: difficulty ?? this.difficulty,
      stability: stability ?? this.stability,
      lastReview: lastReview ?? this.lastReview,
      dueDate: dueDate ?? this.dueDate,
      reviewCount: reviewCount ?? this.reviewCount,
      lapseCount: lapseCount ?? this.lapseCount,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      state: state ?? this.state,
    );
  }

  // Get card status for display
  String get status {
    switch (state) {
      case CardState.newCard:
        return 'Baru';
      case CardState.learning:
        return 'Belajar';
      case CardState.review:
        return 'Review';
      case CardState.relearning:
        return 'Ulangi';
    }
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

// Enhanced Card Manager
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
    final now = DateTime.now();
    return _cards.entries
        .where((entry) => 
            (entry.value.dueDate.isBefore(cutoff) || 
             entry.value.dueDate.isAtSameMomentAs(cutoff)) && 
            (entry.value.dueDate.isAfter(now) || 
             entry.value.dueDate.isAtSameMomentAs(now)))
        .map((entry) => entry.key)
        .toList();
  }

  // Get mastery level of a card (0-1)
  double getMasteryLevel(String id) {
    final card = _cards[id];
    if (card == null) return 0.0;
    
    // Mastery based on stability and difficulty
    final stabilityScore = min(1.0, card.stability / 365.0); // Max 365 days stability
    final difficultyScore = 1.0 - (card.difficulty / FSRS.defaultParameters[10]); // Normalize difficulty
    
    // Review count bonus (more reviews = higher mastery)
    final reviewBonus = min(0.3, card.reviewCount * 0.05);
    
    // Lapse penalty
    final lapsePenalty = min(0.2, card.lapseCount * 0.1);
    
    return (stabilityScore * 0.5 + difficultyScore * 0.3 + reviewBonus - lapsePenalty).clamp(0.0, 1.0);
  }

  // Get mastery level description
  String getMasteryDescription(double mastery) {
    if (mastery < 0.3) return 'Pemula';
    if (mastery < 0.6) return 'Menengah';
    if (mastery < 0.8) return 'Mahir';
    return 'Expert';
  }

  // Get total mastered cards (mastery > 0.7)
  int getMasteredCount() {
    return _cards.keys.where((id) => getMasteryLevel(id) > 0.7).length;
  }

  // Get count of cards due tomorrow
  int getTomorrowDueCount() {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final now = DateTime.now();
    return _cards.values.where((card) => 
      (card.dueDate.isBefore(tomorrow) || card.dueDate.isAtSameMomentAs(tomorrow)) && 
      (card.dueDate.isAfter(now) || card.dueDate.isAtSameMomentAs(now))
    ).length;
  }

  // Get all card IDs
  List<String> getAllCardIds() {
    return _cards.keys.toList();
  }

  // Get card statistics
  Map<String, dynamic> getStatistics() {
    final totalCards = _cards.length;
    final dueCards = getDueCards().length;
    final masteredCards = getMasteredCount();
    final averageMastery = totalCards > 0 
        ? _cards.keys.map(getMasteryLevel).reduce((a, b) => a + b) / totalCards
        : 0.0;

    return {
      'totalCards': totalCards,
      'dueCards': dueCards,
      'masteredCards': masteredCards,
      'averageMastery': averageMastery,
      'tomorrowDue': getTomorrowDueCount(),
    };
  }

  // Initialize cards for a list of question IDs
  void initializeCards(List<String> questionIds) {
    for (var id in questionIds) {
      if (!_cards.containsKey(id)) {
        _cards[id] = fsrs.createCard();
      }
    }
  }

  // Clean up cards that are no longer needed
  void cleanupCards(List<String> validIds) {
    final invalidIds = _cards.keys.where((id) => !validIds.contains(id)).toList();
    for (var id in invalidIds) {
      _cards.remove(id);
    }
  }

  // Serialize all cards to map
  Map<String, dynamic> toMap() {
    return {
      'cards': _cards.map((key, value) => MapEntry(key, value.toMap())),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Deserialize from map
  factory FSRSCardManager.fromMap(Map<String, dynamic> map, {FSRS? fsrs}) {
    final manager = FSRSCardManager(fsrs: fsrs);
    final cardsMap = map['cards'] as Map<String, dynamic>? ?? {};
    
    cardsMap.forEach((key, value) {
      try {
        manager._cards[key] = FSRSCard.fromMap(Map<String, dynamic>.from(value));
      } catch (e) {
        print('Error loading card $key: $e');
      }
    });
    
    return manager;
  }

  // Get cards sorted by mastery level (ascending - weakest first)
  List<String> getCardsSortedByMastery() {
    return _cards.keys.toList()
      ..sort((a, b) => getMasteryLevel(a).compareTo(getMasteryLevel(b)));
  }

  // Get cards sorted by due date (earliest first)
  List<String> getCardsSortedByDueDate() {
    return _cards.keys.toList()
      ..sort((a, b) {
        final cardA = _cards[a]!;
        final cardB = _cards[b]!;
        return cardA.dueDate.compareTo(cardB.dueDate);
      });
  }
}