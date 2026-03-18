import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// PIN numpad widget - displays number buttons for PIN entry
class PinNumpad extends StatefulWidget {
  final Function(String) onPinChanged;
  final int maxLength;
  final bool showDots;
  final bool isShaking;

  const PinNumpad({
    required this.onPinChanged,
    this.maxLength = 6,
    this.showDots = true,
    this.isShaking = false,
    Key? key,
  }) : super(key: key);

  @override
  State<PinNumpad> createState() => _PinNumpadState();
}

class _PinNumpadState extends State<PinNumpad> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  String _pin = '';

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(PinNumpad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShaking && !oldWidget.isShaking) {
      _animateShake();
    }
  }

  void _animateShake() {
    _shakeController.forward(from: 0);
  }

  void _addDigit(String digit) {
    if (_pin.length < widget.maxLength) {
      _pin += digit;
      widget.onPinChanged(_pin);
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      _pin = _pin.substring(0, _pin.length - 1);
      widget.onPinChanged(_pin);
    }
  }

  void _clear() {
    _pin = '';
    widget.onPinChanged(_pin);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = Offset(_shakeOffset(_shakeController.value), 0);
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // PIN display (dots)
            if (widget.showDots)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.maxLength, (index) {
                    return Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 2,
                        ),
                        color: index < _pin.length ? Colors.black : Colors.transparent,
                      ),
                    );
                  }),
                ),
              ),
            // Number grid
            Column(
              children: [
                // Row 1: 1 2 3
                _buildNumpadRow(['1', '2', '3']),
                const SizedBox(height: 12),
                // Row 2: 4 5 6
                _buildNumpadRow(['4', '5', '6']),
                const SizedBox(height: 12),
                // Row 3: 7 8 9
                _buildNumpadRow(['7', '8', '9']),
                const SizedBox(height: 12),
                // Row 4: 0 + backspace/clear
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(width: 64),
                    _buildNumpadButton('0', () => _addDigit('0')),
                    _buildActionButton(
                      icon: Icons.backspace,
                      label: 'Delete',
                      onPressed: _removeDigit,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Clear button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey[300],
                    ),
                    onPressed: _clear,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildNumpadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((digit) => _buildNumpadButton(
                digit,
                () => _addDigit(digit),
              ))
          .toList(),
    );
  }

  Widget _buildNumpadButton(String digit, VoidCallback onPressed) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          shape: const CircleBorder(),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          shape: const CircleBorder(),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

import 'dart:math' as math;

// Helper function for shake animation

double _shakeOffset(double value) => math.sin(value * 4 * math.pi) * 10;
