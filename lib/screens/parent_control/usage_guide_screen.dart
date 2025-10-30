import 'package:flutter/material.dart';
import 'package:Eksplorasi/components/SmoothPress.dart';
import 'package:Eksplorasi/models/languages/index.dart';

class UsageGuideScreen extends StatefulWidget {
  @override
  _UsageGuideScreenState createState() => _UsageGuideScreenState();
}

class _UsageGuideScreenState extends State<UsageGuideScreen> {
  late List<GuideItem> _guideItems;
  int _expandedIndex = -1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await AppLocalizations.init();
      if (mounted) {
        setState(() {
          _initializeGuideItems();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeGuideItems() {
    _guideItems = [
      GuideItem(
        title: AppLocalizations.get('usage_guide.nfc_title'),
        description: AppLocalizations.get('usage_guide.nfc_description'),
        icon: Icons.nfc_rounded,
        color: const Color(0xFF4ECDC4),
      ),
      GuideItem(
        title: AppLocalizations.get('usage_guide.quiz_title'),
        description: AppLocalizations.get('usage_guide.quiz_description'),
        icon: Icons.quiz_rounded,
        color: const Color(0xFFFE6D73),
      ),
      GuideItem(
        title: AppLocalizations.get('usage_guide.parental_title'),
        description: AppLocalizations.get('usage_guide.parental_description'),
        icon: Icons.family_restroom_rounded,
        color: const Color(0xFFFED766),
      ),
      GuideItem(
        title: AppLocalizations.get('usage_guide.tips_title'),
        description: AppLocalizations.get('usage_guide.tips_description'),
        icon: Icons.lightbulb_rounded,
        color: const Color(0xFFA5D8FF),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            // Background circles
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFFED766).withOpacity(0.1),
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
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Back button
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
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2D5A7E),
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Main content
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D5A7E)),
                ),
              )
            else
              Column(
                children: [
                  const SizedBox(height: 40),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header Icon
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
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFFED766),
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 60,
                              color: Color(0xFFFED766),
                            ),
                          ),

                          const SizedBox(height: 30),
                          
                          // Title
                          Text(
                            AppLocalizations.get('usage_guide.title'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D5A7E),
                              fontFamily: 'ComicNeue',
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            AppLocalizations.get('usage_guide.subtitle'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                              fontFamily: 'ComicNeue',
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),
                          
                          // Guide Items
                          ..._guideItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _buildGuideItem(item, index);
                          }).toList(),
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

  Widget _buildGuideItem(GuideItem item, int index) {
    bool isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: SmoothPressButton(
        onPressed: () {
          setState(() {
            _expandedIndex = isExpanded ? -1 : index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: item.color.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    
                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D5A7E),
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontFamily: 'ComicNeue',
                            ),
                            maxLines: isExpanded ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Expand Icon
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: item.color,
                      size: 28,
                    ),
                  ],
                ),
                
                // Expanded Content
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Divider(color: item.color.withOpacity(0.3), height: 1),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getGuideContent(index),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D5A7E),
                        height: 1.6,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGuideContent(int index) {
    switch (index) {
      case 0:
        return AppLocalizations.get('usage_guide.nfc_content');
      case 1:
        return AppLocalizations.get('usage_guide.quiz_content');
      case 2:
        return AppLocalizations.get('usage_guide.parental_content');
      case 3:
        return AppLocalizations.get('usage_guide.tips_content');
      default:
        return AppLocalizations.get('usage_guide.default_content');
    }
  }
}

class GuideItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const GuideItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}