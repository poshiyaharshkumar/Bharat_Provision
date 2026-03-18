import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_numpad.dart';

/// PIN verification screen - used for sensitive operations
class PinVerificationScreen extends ConsumerStatefulWidget {
  final String title;
  final Function(bool) onVerified;
  final String? targetRole;

  const PinVerificationScreen({
    required this.title,
    required this.onVerified,
    this.targetRole,
    super.key,
  });

  @override
  ConsumerState<PinVerificationScreen> createState() =>
      _PinVerificationScreenState();
}

class _PinVerificationScreenState extends ConsumerState<PinVerificationScreen> {
  String _enteredPin = '';
  String _errorMessage = '';
  bool _isShaking = false;

  Future<void> _verifyPin() async {
    final session = ref.read(authSessionProvider);
    if (session == null) {
      _showError('No active session');
      return;
    }

    final pinStorage = ref.read(pinStorageProvider);
    final isValid = await pinStorage.verifyPin(session.role, _enteredPin);

    if (isValid) {
      widget.onVerified(true);
      Navigator.of(context).pop(true);
    } else {
      _showError('Wrong PIN');
      _triggerShakeAnimation();
      _clearPin();
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _triggerShakeAnimation() {
    setState(() {
      _isShaking = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isShaking = false;
      });
    });
  }

  void _clearPin() {
    setState(() {
      _enteredPin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuperadmin = ref.watch(authSessionProvider)?.role == 'superadmin';
    final maxLength = isSuperadmin ? 6 : 4;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Re-verify PIN',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              PinNumpad(
                onPinChanged: (pin) {
                  setState(() {
                    _enteredPin = pin;
                  });
                  if (pin.length == maxLength) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _verifyPin();
                    });
                  }
                },
                maxLength: maxLength,
                isShaking: _isShaking,
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Change PIN screen
class ChangePinScreen extends ConsumerStatefulWidget {
  final String forRole; // 'own', 'employee', 'admin'

  const ChangePinScreen({required this.forRole, super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  int _step = 0; // 0: verify old PIN, 1: enter new PIN, 2: confirm new PIN
  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String _errorMessage = '';
  bool _isShaking = false;

  Future<void> _verifyOldPin() async {
    final session = ref.read(authSessionProvider);
    if (session == null) {
      _showError('No active session');
      return;
    }

    final pinStorage = ref.read(pinStorageProvider);
    final role = widget.forRole == 'own' ? session.role : widget.forRole;
    final isValid = await pinStorage.verifyPin(role, _oldPin);

    if (isValid) {
      setState(() {
        _step = 1;
        _oldPin = '';
        _errorMessage = '';
      });
    } else {
      _showError('Wrong PIN');
      _triggerShakeAnimation();
      _clearPin();
    }
  }

  void _enterNewPin() {
    if (_newPin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    setState(() {
      _step = 2;
      _errorMessage = '';
    });
  }

  Future<void> _confirmNewPin() async {
    if (_newPin != _confirmPin) {
      _showError('PINs do not match');
      _triggerShakeAnimation();
      _clearPin();
      return;
    }

    final session = ref.read(authSessionProvider);
    if (session == null) {
      _showError('No active session');
      return;
    }

    final pinStorage = ref.read(pinStorageProvider);
    final role = widget.forRole == 'own' ? session.role : widget.forRole;

    try {
      await pinStorage.setPinHash(role, _newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN changed successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Error changing PIN: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _triggerShakeAnimation() {
    setState(() {
      _isShaking = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isShaking = false;
      });
    });
  }

  void _clearPin() {
    setState(() {
      if (_step == 0) {
        _oldPin = '';
      } else if (_step == 1) {
        _newPin = '';
      } else {
        _confirmPin = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.forRole == 'own'
              ? 'Change My PIN'
              : 'Change ${widget.forRole} PIN',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepIndicator(
                    number: 1,
                    isActive: _step >= 0,
                    label: 'Old PIN',
                  ),
                  Container(
                    width: 40,
                    height: 2,
                    color: _step >= 1 ? Colors.blue : Colors.grey[300],
                  ),
                  _StepIndicator(
                    number: 2,
                    isActive: _step >= 1,
                    label: 'New PIN',
                  ),
                  Container(
                    width: 40,
                    height: 2,
                    color: _step >= 2 ? Colors.blue : Colors.grey[300],
                  ),
                  _StepIndicator(
                    number: 3,
                    isActive: _step >= 2,
                    label: 'Confirm',
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Step content
              if (_step == 0) ...[
                Text(
                  'Enter Old PIN',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                PinNumpad(
                  onPinChanged: (pin) {
                    setState(() {
                      _oldPin = pin;
                    });
                    if (pin.length == 4 || pin.length == 6) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!_isShaking) _verifyOldPin();
                      });
                    }
                  },
                  maxLength: 6,
                  isShaking: _isShaking,
                ),
              ] else if (_step == 1) ...[
                Text(
                  'Enter New PIN',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('(Superadmin requires 6 digits)'),
                const SizedBox(height: 24),
                PinNumpad(
                  onPinChanged: (pin) {
                    setState(() {
                      _newPin = pin;
                    });
                  },
                  maxLength: 6,
                  isShaking: _isShaking,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _newPin.length >= 4 ? _enterNewPin : null,
                    child: const Text('Continue'),
                  ),
                ),
              ] else if (_step == 2) ...[
                Text(
                  'Confirm New PIN',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                PinNumpad(
                  onPinChanged: (pin) {
                    setState(() {
                      _confirmPin = pin;
                    });
                    if (pin.length == _newPin.length && pin.length >= 4) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!_isShaking) _confirmNewPin();
                      });
                    }
                  },
                  maxLength: 6,
                  isShaking: _isShaking,
                ),
              ],
              const SizedBox(height: 24),
              // Error message
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              // Back button
              if (_step > 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                    ),
                    onPressed: () {
                      setState(() {
                        _step--;
                        _errorMessage = '';
                      });
                    },
                    child: const Text('Back'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int number;
  final bool isActive;
  final String label;

  const _StepIndicator({
    required this.number,
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
