import 'package:flutter/material.dart';
import 'package:spah_generator/components/SmoothPress.dart';
import 'package:spah_generator/utils/parent_control.dart';

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

  @override
  void initState() {
    super.initState();
    _pinFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _pinFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _verifyPassword() async {
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
      _errorMessage = '';
    });

    final isCorrect = await ParentControlService.verifyPassword(
      _passwordController.text,
    );

    if (isCorrect) {
      widget.onSuccess();
    } else {
      setState(() {
        _errorMessage = 'PIN salah!';
        _isLoading = false;
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      body: SafeArea(
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
                  border: Border.all(color: Color(0xFF4ECDC4), width: 4),
                ),
                child: Icon(Icons.lock, size: 60, color: Color(0xFF4ECDC4)),
              ),
              SizedBox(height: 30),
              Text(
                'Kontrol Orang Tua',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4ECDC4),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Masukkan PIN untuk mengakses',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(_pinFocusNode);
                },
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 4; i++)
                            Container(
                              width: 50,
                              height: 50,
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: _passwordController.text.length > i 
                                    ? Color(0xFF4ECDC4).withOpacity(0.1) 
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _passwordController.text.length > i 
                                      ? Color(0xFF4ECDC4) 
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  _passwordController.text.length > i ? '•' : '',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Color(0xFF4ECDC4),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ketuk untuk memasukkan PIN',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
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
                  style: TextStyle(fontSize: 1, color: Colors.transparent),
                  decoration: InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.length == 4) {
                      Future.delayed(Duration(milliseconds: 300), () {
                        _verifyPassword();
                      });
                    }
                  },
                ),
              ),
              
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Color(0xFFFE6D73), fontSize: 16),
                ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : SmoothPressButton(
                      onPressed: _verifyPassword,
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xFF4ECDC4),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'MASUK',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'BATAL',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}