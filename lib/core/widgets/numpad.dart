import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef NumpadOnChanged = void Function(String value);

class Numpad extends StatefulWidget {
  const Numpad({
    super.key,
    required this.onChanged,
    this.onSubmit,
    this.initialValue = '',
  });

  final NumpadOnChanged onChanged;
  final VoidCallback? onSubmit;
  final String initialValue;

  @override
  State<Numpad> createState() => _NumpadState();
}

class _NumpadState extends State<Numpad> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(Numpad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void append(String digit) {
    final next = '${_controller.text}$digit';
    _controller.text = next;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: next.length),
    );
    widget.onChanged(next);
  }

  void backspace() {
    if (_controller.text.isEmpty) return;
    final next = _controller.text.substring(0, _controller.text.length - 1);
    _controller.text = next;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: next.length),
    );
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    Widget keyButton(String label, {VoidCallback? onTap}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: onTap ?? () => append(label),
              child: Text(
                label,
                style: GoogleFonts.notoSansGujarati(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            keyButton('1'),
            keyButton('2'),
            keyButton('3'),
          ],
        ),
        Row(
          children: [
            keyButton('4'),
            keyButton('5'),
            keyButton('6'),
          ],
        ),
        Row(
          children: [
            keyButton('7'),
            keyButton('8'),
            keyButton('9'),
          ],
        ),
        Row(
          children: [
            keyButton('.'),
            keyButton('0'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: backspace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                    ),
                    child: const Icon(Icons.backspace),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.onSubmit != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onSubmit,
                child: Text(
                  'ઓકે',
                  style: GoogleFonts.notoSansGujarati(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
