import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinBox extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const PinBox({
    Key? key,
    required this.length,
    required this.onCompleted,
    required this.onChanged,
    this.autofocus = false,
  }) : super(key: key);

  @override
  _PinBoxState createState() => _PinBoxState();
}

class _PinBoxState extends State<PinBox> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  String _currentPin = '';

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      });
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      setState(() {
        _currentPin = _getCurrentPin();
      });

      widget.onChanged(_currentPin);

      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }

      if (_currentPin.length == widget.length) {
        widget.onCompleted(_currentPin);
      }
    }
  }

  void _onKeyAction(RawKeyEvent event, int index) {
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        
        setState(() {
          _currentPin = _getCurrentPin();
        });
        
        widget.onChanged(_currentPin);
      }
    }
  }

  String _getCurrentPin() {
    String pin = '';
    for (var controller in _controllers) {
      pin += controller.text;
    }
    return pin;
  }

  void _clearAll() {
    for (var controller in _controllers) {
      controller.clear();
    }
    for (var focusNode in _focusNodes) {
      focusNode.unfocus();
    }
    setState(() {
      _currentPin = '';
    });
    widget.onChanged('');
    
    if (widget.autofocus) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              return Container(
                width: 48,
                height: 48,
                child: _SingleDigitBox(
                  focusNode: _focusNodes[index],
                  controller: _controllers[index],
                  onChanged: (value) => _onDigitChanged(value, index),
                  onKeyAction: (event) => _onKeyAction(event, index),
                  hasValue: _controllers[index].text.isNotEmpty,
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Masukkan ${widget.length} digit PIN',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _SingleDigitBox extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<RawKeyEvent> onKeyAction;
  final bool hasValue;

  const _SingleDigitBox({
    required this.focusNode,
    required this.controller,
    required this.onChanged,
    required this.onKeyAction,
    required this.hasValue,
  });

  @override
  __SingleDigitBoxState createState() => __SingleDigitBoxState();
}

class __SingleDigitBoxState extends State<_SingleDigitBox> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Color(0xFF4ECDC4).withOpacity(0.2),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(_SingleDigitBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasValue != oldWidget.hasValue) {
      if (widget.hasValue) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              border: Border.all(
                color: widget.focusNode.hasFocus 
                    ? Color(0xFF4ECDC4) 
                    : Colors.grey[400]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: widget.onKeyAction,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4ECDC4),
                ),
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}