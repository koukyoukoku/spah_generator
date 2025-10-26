import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Eksplorasi/components/SmoothPress.dart';
import 'package:Eksplorasi/utils/parent_control.dart';

class PasswordScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const PasswordScreen({required this.onSuccess});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  FocusNode _pinFocusNode = FocusNode();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isVerifying = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _pinFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_pinFocusNode);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pinFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _verifyPassword() async {
    if (_isVerifying) return;

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan PIN';
      });
      return;
    }

    if (_passwordController.text.length != 4) {
      setState(() {
        _errorMessage = 'PIN harus 4 digit';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      final isCorrect = await ParentControlService.verifyPassword(
        _passwordController.text,
      );

      if (!mounted) return;

      if (isCorrect) {
        widget.onSuccess();
      } else {
        setState(() {
          _errorMessage = 'PIN salah! Coba lagi.';
          _isLoading = false;
          _isVerifying = false;
        });
        _passwordController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Terjadi kesalahan. Coba lagi.';
        _isLoading = false;
        _isVerifying = false;
      });
      _passwordController.clear();
    }
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _errorMessage = '';
    });
    
    _debounceTimer?.cancel();
    
    if (value.length == 4) {
      _debounceTimer = Timer(Duration(milliseconds: 300), () {
        if (!_isVerifying && mounted) {
          _verifyPassword();
        }
      });
    }
  }

  void _handleBack() {
    _debounceTimer?.cancel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handlePinButtonPressed(String digit) {
    if (_passwordController.text.length < 4) {
      _passwordController.text += digit;
      _onPasswordChanged(_passwordController.text);
      _pinFocusNode.requestFocus();
    }
  }

  void _handleBackspace() {
    if (_passwordController.text.isNotEmpty) {
      _passwordController.text = _passwordController.text
          .substring(0, _passwordController.text.length - 1);
      _onPasswordChanged(_passwordController.text);
      _pinFocusNode.requestFocus();
    }
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
                  onPressed: _handleBack,
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
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 60,
                                color: Color(0xFF4ECDC4),
                              ),
                              if (_isLoading)
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4ECDC4),
                                  ),
                                  strokeWidth: 3,
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),
                        Text(
                          'Kontrol Orang Tua',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A7E),
                            fontFamily: 'ComicNeue',
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'Masukkan PIN 4 digit untuk melanjutkan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontFamily: 'ComicNeue',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 40),
                        Container(
                          height: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              bool hasValue =
                                  _passwordController.text.length > index;
                              return Container(
                                width: 50,
                                height: 50,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: hasValue
                                      ? Color(0xFF4ECDC4)
                                      : Colors.white,
                                  border: Border.all(
                                    color: hasValue
                                        ? Color(0xFF2AA8A0)
                                        : Color(0xFFCCCCCC),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    hasValue ? '●' : '',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        SizedBox(height: 20),
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFE6E8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFFF6B6B)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFFF6B6B),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 14,
                                      fontFamily: 'ComicNeue',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 30),
                        Container(
                          width: 0,
                          height: 0,
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _pinFocusNode,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 1,
                              color: Colors.transparent,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              border: InputBorder.none,
                            ),
                            onChanged: _onPasswordChanged,
                            readOnly: true,
                            showCursor: false,
                            enableInteractiveSelection: false,
                          ),
                        ),

                        SizedBox(height: 20),
                        _buildManualPinPad(),
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

  Widget _buildManualPinPad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) {
          return SizedBox();
        } else if (index == 10) {
          return _buildPinButton('0', onPressed: () {
            _handlePinButtonPressed('0');
          });
        } else if (index == 11) {
          return _buildPinButton(
            Icons.backspace_outlined,
            onPressed: _handleBackspace,
            isIcon: true,
          );
        } else {
          final number = (index + 1).toString();
          return _buildPinButton(number, onPressed: () {
            _handlePinButtonPressed(number);
          });
        }
      },
    );
  }

  Widget _buildPinButton(dynamic content, {required VoidCallback onPressed, bool isIcon = false}) {
    return SmoothPressButton(
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Color(0xFF4ECDC4).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: isIcon
              ? Icon(
                  content as IconData,
                  color: Color(0xFF2D5A7E),
                  size: 24,
                )
              : Text(
                  content as String,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D5A7E),
                    fontFamily: 'ComicNeue',
                  ),
                ),
        ),
      ),
    );
  }
}