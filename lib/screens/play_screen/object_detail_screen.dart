import 'package:flutter/material.dart';
import 'package:Eksplorasi/utils/tts_service.dart';
import 'package:Eksplorasi/models/languages/index.dart';

class ObjectDetailScreen extends StatefulWidget {
  final String objectName;
  final String objectId;
  final bool isEnglish;
  final Map<String, dynamic>? objectData;

  const ObjectDetailScreen({
    Key? key,
    required this.objectName,
    required this.objectId,
    required this.isEnglish,
    this.objectData,
  }) : super(key: key);

  @override
  _ObjectDetailScreenState createState() => _ObjectDetailScreenState();
}

class _ObjectDetailScreenState extends State<ObjectDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  int _currentStep = 0;
  bool _isPlaying = false;
  List<String> _spellingSteps = [];
  List<List<int>> _syllableRanges = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Color(0xFFFED766),
    ).animate(_animationController);

    _prepareSpellingSteps();
    _startSequence();
  }

  void _prepareSpellingSteps() {
    String name = widget.objectName;
    List<String> syllables = [];
    
    if (widget.objectData != null && widget.objectData!['syllables'] != null) {
      final syllablesData = widget.objectData!['syllables'];
      String languageKey = widget.isEnglish ? 'en' : 'id';
      
      print('🔍 Syllables data: $syllablesData');
      print('🔍 Language key: $languageKey');
      
      if (syllablesData.containsKey(languageKey)) {
        syllables = List<String>.from(syllablesData[languageKey]);
        print('✅ Using Firebase syllables: $syllables');
      } else {
        syllables = _getFallbackSyllables(name, widget.isEnglish);
        print('⚠️ Using fallback syllables: $syllables');
      }
    } else {
      syllables = _getFallbackSyllables(name, widget.isEnglish);
      print('⚠️ No syllables data, using fallback: $syllables');
    }

    _syllableRanges = _calculateSyllableRanges(name, syllables);
    
    _spellingSteps = [name];
    _spellingSteps.addAll(syllables);
    _spellingSteps.add(name);
    
    print('📝 Spelling steps: $_spellingSteps');
  }

  List<String> _getFallbackSyllables(String word, bool isEnglish) {
    final Map<String, List<String>> englishSyllables = {
      'Apple': ['A', 'pple'],
      'Banana': ['Ba', 'na', 'na'],
      'Car': ['Car'],
      'Ball': ['Ball'],
      'Book': ['Book'],
      'Pencil': ['Pen', 'cil'],
      'House': ['House'],
      'Tree': ['Tree'],
      'Cat': ['Cat'],
      'Dog': ['Dog'],
    };

    final Map<String, List<String>> indonesianSyllables = {
      'Apel': ['A', 'pel'],
      'Pisang': ['Pi', 'sang'],
      'Mobil': ['Mo', 'bil'],
      'Bola': ['Bo', 'la'],
      'Buku': ['Bu', 'ku'],
      'Pensil': ['Pen', 'sil'],
      'Rumah': ['Ru', 'mah'],
      'Pohon': ['Po', 'hon'],
      'Kucing': ['Ku', 'cing'],
      'Anjing': ['An', 'jing'],
    };

    if (isEnglish) {
      return englishSyllables[word] ?? _splitIntoSyllables(word, isEnglish);
    } else {
      return indonesianSyllables[word] ?? _splitIntoSyllables(word, isEnglish);
    }
  }

  List<String> _splitIntoSyllables(String word, bool isEnglish) {
    if (word.length <= 3) return [word];
    
    List<String> syllables = [];
    String currentSyllable = '';
    
    for (int i = 0; i < word.length; i++) {
      currentSyllable += word[i];
      
      if (isEnglish) {
        bool isVowel = 'aeiouAEIOU'.contains(word[i]);
        bool isLastChar = i == word.length - 1;
        
        if (isVowel && !isLastChar) {
          if (i + 1 < word.length && !'aeiouAEIOU'.contains(word[i + 1])) {
            syllables.add(currentSyllable);
            currentSyllable = '';
          }
        }
      } else {
        if (currentSyllable.length >= 2 && i < word.length - 1) {
          syllables.add(currentSyllable);
          currentSyllable = '';
        }
      }
    }
    
    if (currentSyllable.isNotEmpty) {
      syllables.add(currentSyllable);
    }
    
    return syllables.isNotEmpty ? syllables : [word];
  }

  List<List<int>> _calculateSyllableRanges(String fullWord, List<String> syllables) {
    List<List<int>> ranges = [];
    int currentIndex = 0;
    
    for (String syllable in syllables) {
      int start = currentIndex;
      int end = currentIndex + syllable.length;
      ranges.add([start, end]);
      currentIndex = end;
    }
    
    return ranges;
  }

  void _startSequence() async {
    if (_isPlaying) return;
    
    setState(() {
      _isPlaying = true;
      _currentStep = 0;
    });

    for (int i = 0; i < _spellingSteps.length; i++) {
      if (!mounted) break;
      
      setState(() {
        _currentStep = i;
      });

      _animationController.forward(from: 0);
      
      await Future.delayed(Duration(milliseconds: 300));
      
      await _speakSyllable(_spellingSteps[i], i);
      _animationController.reverse();
      
      if (i < _spellingSteps.length - 1) {
        await Future.delayed(Duration(milliseconds: 800));
      }
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _speakSyllable(String text, int stepIndex) async {
    if (!TTSService.isAvailable) return;

    String currentLanguage = widget.isEnglish ? 'en' : 'id';
    await TTSService.setLanguage(currentLanguage);
    
    print('🗣️ Speaking ($currentLanguage): "$text" at step $stepIndex');
    
    if (stepIndex > 0 && stepIndex < _spellingSteps.length - 1) {
      await TTSService.speak(text);
      
      int delay = text.length * 400 + 600;
      await Future.delayed(Duration(milliseconds: delay));
    } else {
      await TTSService.speak(text);
      
      int delay = text.length * 300 + 1000;
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  Widget _buildSyllableHighlight() {
    String fullWord = widget.objectName;
    
    if (_currentStep == 0 || _currentStep >= _spellingSteps.length - 1) {
      return _buildHighlightedText(fullWord, 0, fullWord.length);
    } else {
      int syllableIndex = _currentStep - 1;
      if (syllableIndex < _syllableRanges.length) {
        List<int> range = _syllableRanges[syllableIndex];
        return _buildPartialHighlight(fullWord, range[0], range[1]);
      } else {
        return Text(
          fullWord,
          style: TextStyle(
            fontSize: 48,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontFamily: 'ComicNeue',
          ),
        );
      }
    }
  }

  Widget _buildPartialHighlight(String text, int start, int end) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (start > 0)
          Text(
            text.substring(0, start),
            style: TextStyle(
              fontSize: 48,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
            ),
          ),
        
        _buildHighlightedText(text.substring(start, end), 0, end - start),
        
        if (end < text.length)
          Text(
            text.substring(end),
            style: TextStyle(
              fontSize: 48,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedText(String text, int start, int length) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 48,
              color: Color(0xFF2D5A7E),
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
            ),
          ),
        );
      },
    );
  }

  String _getStepDescription() {
    if (_currentStep == 0) {
      return widget.isEnglish ? "Say the word" : "Ucapkan kata";
    } else if (_currentStep >= _spellingSteps.length - 1) {
      return widget.isEnglish ? "Say it again!" : "Ulangi kata!";
    } else {
      int syllableNumber = _currentStep;
      return widget.isEnglish 
          ? "Syllable $syllableNumber" 
          : "Suku kata $syllableNumber";
    }
  }

  String _getCurrentSyllableText() {
    if (_currentStep == 0) {
      return widget.objectName;
    } else if (_currentStep >= _spellingSteps.length - 1) {
      return widget.objectName;
    } else {
      return _spellingSteps[_currentStep];
    }
  }

  String _getImagePath() {
    if (widget.objectData != null && widget.objectData!['image'] != null) {
      return widget.objectData!['image'].toString();
    }
    
    final Map<String, String> fallbackImages = {
      'Apple': 'assets/images/apple.png',
      'Apel': 'assets/images/apple.png',
      'Banana': 'assets/images/banana.png',
      'Pisang': 'assets/images/banana.png',
      'Car': 'assets/images/car.png',
      'Mobil': 'assets/images/car.png',
      'Ball': 'assets/images/ball.png',
      'Bola': 'assets/images/ball.png',
      'Book': 'assets/images/book.png',
      'Buku': 'assets/images/book.png',
      'Pencil': 'assets/images/pencil.png',
      'Pensil': 'assets/images/pencil.png',
      'House': 'assets/images/house.png',
      'Rumah': 'assets/images/house.png',
      'Tree': 'assets/images/tree.png',
      'Pohon': 'assets/images/tree.png',
      'Cat': 'assets/images/cat.png',
      'Kucing': 'assets/images/cat.png',
      'Dog': 'assets/images/dog.png',
      'Anjing': 'assets/images/dog.png',
      'Table': 'assets/images/table.png',
      'Meja': 'assets/images/table.png',
      'Chair': 'assets/images/chair.png',
      'Kursi': 'assets/images/chair.png',
      'Hat': 'assets/images/hat.png',
      'Topi': 'assets/images/hat.png',
      'Shoe': 'assets/images/shoe.png',
      'Sepatu': 'assets/images/shoe.png',
      'Flower': 'assets/images/flower.png',
      'Bunga': 'assets/images/flower.png',
      'Sun': 'assets/images/sun.png',
      'Matahari': 'assets/images/sun.png',
      'Moon': 'assets/images/moon.png',
      'Bulan': 'assets/images/moon.png',
      'Star': 'assets/images/star.png',
      'Bintang': 'assets/images/star.png',
    };
    
    return fallbackImages[widget.objectName] ?? 'assets/images/placeholder.png';
  }

  @override
  Widget build(BuildContext context) {
    String imagePath = _getImagePath();

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
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            Column(
              children: [
                SizedBox(height: 40),
                Container(
                  width: 200,
                  height: 200,
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
                      color: Color(0xFF4ECDC4),
                      width: 4,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      imagePath,
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.photo,
                          size: 80,
                          color: Color(0xFF4ECDC4),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  _getStepDescription(),
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF2D5A7E),
                    fontFamily: 'ComicNeue',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _getCurrentSyllableText(),
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF4ECDC4),
                    fontFamily: 'ComicNeue',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.symmetric(horizontal: 20),
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
                  ),
                  child: Center(
                    child: _buildSyllableHighlight(),
                  ),
                ),

                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_spellingSteps.length, (index) {
                    return Container(
                      width: 12,
                      height: 12,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _currentStep 
                            ? Color(0xFF4ECDC4)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),

                SizedBox(height: 40),
                if (!_isPlaying)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: _startSequence,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4ECDC4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            widget.isEnglish ? "Play Again" : "Mainkan Lagi",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ComicNeue',
                            ),
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

  @override
  void dispose() {
    _animationController.dispose();
    TTSService.stop();
    super.dispose();
  }
}