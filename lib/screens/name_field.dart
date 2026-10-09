import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/spot_themes.dart';

/// A renameable profile name field that persists as the user types.
///
/// Every keystroke is saved (through [onSave]); when the field loses focus
/// the current text is committed one final time, and the check button (or
/// keyboard-done) also commits explicitly. Never rebuild-driven, so the
/// cursor never jumps on rebuilds.
class NameField extends StatefulWidget {
  final SpotAudio audio;
  final SpotThemeDef theme;
  final String label;
  final String initial;
  final Future<void> Function(String) onSave;

  const NameField({
    super.key,
    required this.audio,
    required this.theme,
    required this.label,
    required this.initial,
    required this.onSave,
  });

  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  late final TextEditingController _ctl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initial);
    _focus = FocusNode()..addListener(_commitOnFocusLoss);
  }

  void _commitOnFocusLoss() {
    if (!_focus.hasFocus) {
      widget.onSave(_ctl.text);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_commitOnFocusLoss);
    _focus.dispose();
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctl,
            focusNode: _focus,
            style:
                TextStyle(color: widget.theme.text, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: TextStyle(color: widget.theme.textDim),
              hintText: 'Type a name…',
              hintStyle: TextStyle(color: widget.theme.textDim),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.theme.cardEdge)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.theme.accent)),
            ),
            // Save on every keystroke.
            onChanged: (v) => widget.onSave(v),
            onSubmitted: (v) {
              widget.audio.click();
              widget.onSave(v);
              _focus.unfocus();
            },
          ),
        ),
        IconButton(
          onPressed: () {
            widget.audio.click();
            widget.onSave(_ctl.text);
            _focus.unfocus();
          },
          icon: Icon(Icons.check, color: widget.theme.accent),
          tooltip: 'Save name',
        ),
      ],
    );
  }
}
