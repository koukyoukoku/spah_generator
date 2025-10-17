import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spah_generator/components/SmoothPress.dart';
import 'package:spah_generator/utils/widgets/pin_box.dart';
import 'package:spah_generator/utils/widgets/success_checkmark.dart';

class ChangePinScreen extends StatefulWidget {
  @override
  _ChangePinScreenState createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String _newPin = '';
  String _confirmPin = '';
  String _message = '';
  bool _showConfirm = false;
  bool _isSuccess = false;

  Future<void> _changePassword() async {
    if (_newPin.length != 4) {
      setState(() {
        _message = 'PIN harus 4 digit';
      });
      return;
    }

    if (_newPin != _confirmPin) {
      setState(() {
        _message = 'PIN tidak cocok';
        _showConfirm = false;
        _confirmPin = '';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_password', _newPin);
    
    setState(() {
      _isSuccess = true;
      _message = '';
    });
  }

  void _onNewPinCompleted(String pin) {
    setState(() {
      _newPin = pin;
      _showConfirm = true;
      _message = '';
    });
  }

  void _onConfirmPinCompleted(String pin) {
    setState(() {
      _confirmPin = pin;
    });
    if (pin.length == 4) {
      _changePassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFF4ECDC4),
        title: Text(
          'Ubah PIN',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(25),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF4ECDC4),
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.lock,
                  size: 50,
                  color: Color(0xFF4ECDC4),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Ubah PIN Akses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4ECDC4),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Buat PIN baru untuk mengakses kontrol orang tua',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: _isSuccess ? _buildSuccessWidget() : _buildFormWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormWidget() {
    return Column(
      children: [
        Text(
          'PIN default: 1234',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 30),
        
        if (!_showConfirm) ...[
          PinBox(
            length: 4,
            onCompleted: _onNewPinCompleted,
            onChanged: (pin) {
              setState(() {
                _newPin = pin;
              });
            },
            autofocus: true,
          ),
        ] else ...[
          Text(
            'Konfirmasi PIN Baru',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          PinBox(
            length: 4,
            onCompleted: _onConfirmPinCompleted,
            onChanged: (pin) {
              setState(() {
                _confirmPin = pin;
              });
            },
            autofocus: true,
          ),
        ],
        
        if (_message.isNotEmpty && !_isSuccess) ...[
          SizedBox(height: 20),
          Text(
            _message,
            style: TextStyle(
              color: Color(0xFFFE6D73),
              fontSize: 14,
            ),
          ),
        ],
        
        if (_showConfirm && !_isSuccess) ...[
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmoothPressButton(
                onPressed: () {
                  setState(() {
                    _showConfirm = false;
                    _confirmPin = '';
                    _message = '';
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Ulangi PIN',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessWidget() {
    return Column(
      children: [
        SuccessCheckmark(),
        SizedBox(height: 20),
        Text(
          'PIN berhasil diubah!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        SmoothPressButton(
          onPressed: () {
            setState(() {
              _isSuccess = false;
              _showConfirm = false;
              _newPin = '';
              _confirmPin = '';
              _message = '';
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF4ECDC4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Ubah PIN Lagi',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}