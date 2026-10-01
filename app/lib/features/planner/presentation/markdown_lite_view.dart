import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/markdown_lite.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] outside the app after a confirmation (notes links, task URL).
Future<void> openExternalLink(BuildContext context, String url) async {
  final l = context.l10n;
  final ok = await confirmDialog(
    context,
    title: l.tasksOpenLinkTitle,
    body: l.tasksOpenLinkBody(url),
    confirmLabel: l.actionOpen,
  );
  if (!ok) return;
  final uri = Uri.tryParse(url.startsWith('www.') ? 'https://$url' : url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Renders markdown-lite notes (T3.1.15): bold, italic, one heading level, lists, display-only
/// checkboxes, code spans and auto-detected links (opened after confirmation). Each block's
/// direction follows its first strong character (mixed Arabic/Latin notes).
class MarkdownLiteView extends StatefulWidget {
  const MarkdownLiteView(this.source, {super.key, this.style, this.maxBlocks});

  final String source;
  final TextStyle? style;

  /// Renders only the first N blocks (previews).
  final int? maxBlocks;

  @override
  State<MarkdownLiteView> createState() => _MarkdownLiteViewState();
}

class _MarkdownLiteViewState extends State<MarkdownLiteView> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  InlineSpan _span(MdInline i, TextStyle base) {
    var style = base;
    if (i.bold) style = style.copyWith(fontWeight: FontWeight.w700);
    if (i.italic) style = style.copyWith(fontStyle: FontStyle.italic);
    if (i.code) {
      style = style.copyWith(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Courier', 'monospace'],
        backgroundColor: context.colors.surfaceContainerHighest,
      );
    }
    final link = i.link;
    if (link == null) return TextSpan(text: i.text, style: style);
    final recognizer = TapGestureRecognizer()..onTap = () => openExternalLink(context, link);
    _recognizers.add(recognizer);
    return TextSpan(
      text: i.text,
      style: style.copyWith(color: context.colors.primary, decoration: TextDecoration.underline),
      recognizer: recognizer,
      semanticsLabel: i.text,
    );
  }

  Widget _text(MdBlock block, TextStyle style) {
    final text = Text.rich(TextSpan(children: [for (final i in block.inlines) _span(i, style)]), style: style);
    return switch (block.direction) {
      MdDirection.rtl => Directionality(textDirection: TextDirection.rtl, child: text),
      MdDirection.ltr => Directionality(textDirection: TextDirection.ltr, child: text),
      MdDirection.neutral => text,
    };
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final base = widget.style ?? context.text.bodyMedium ?? const TextStyle();
    var blocks = parseMarkdownLite(widget.source);
    final max = widget.maxBlocks;
    if (max != null && blocks.length > max) blocks = blocks.take(max).toList();
    // A list item follows its own first strong character: an Arabic item in an LTR note puts
    // its marker on the right (and vice versa).
    Widget item(int indent, Widget marker, MdBlock block) {
      final row = Padding(
        padding: EdgeInsetsDirectional.only(start: indent * Space.lg, top: Space.xxs, bottom: Space.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: Space.xl, child: marker),
            Expanded(child: _text(block, base)),
          ],
        ),
      );
      return switch (block.direction) {
        MdDirection.rtl => Directionality(textDirection: TextDirection.rtl, child: row),
        MdDirection.ltr => Directionality(textDirection: TextDirection.ltr, child: row),
        MdDirection.neutral => row,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final b in blocks)
          switch (b) {
            MdHeading() => Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.xs, bottom: Space.xxs),
              child: Semantics(
                header: true,
                child: _text(b, (context.text.titleMedium ?? base).copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            MdBullet(:final indent) => item(indent, Text('•', style: base), b),
            MdNumbered(:final number, :final indent) => item(indent, Text('$number.', style: base), b),
            MdCheckbox(:final checked, :final indent) => item(
              indent,
              Icon(
                checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
                color: context.colors.onSurfaceVariant,
              ),
              b,
            ),
            MdSpacer() => const SizedBox(height: Space.sm),
            MdParagraph() => _text(b, base),
          },
      ],
    );
  }
}

/// Notes editor with a compact markdown-lite toolbar and a preview toggle (T3.1.15).
class MarkdownLiteField extends StatefulWidget {
  const MarkdownLiteField({required this.controller, super.key, this.hint, this.onChanged, this.fieldKey});

  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;

  @override
  State<MarkdownLiteField> createState() => _MarkdownLiteFieldState();
}

class _MarkdownLiteFieldState extends State<MarkdownLiteField> {
  bool _preview = false;

  TextEditingController get _c => widget.controller;

  void _changed() => widget.onChanged?.call(_c.text);

  /// Wraps the selection (or inserts a placeholder pair) with [marker].
  void _wrap(String marker) {
    final text = _c.text;
    final sel = _c.selection.isValid ? _c.selection : TextSelection.collapsed(offset: text.length);
    final selected = sel.textInside(text);
    final replaced = '$marker$selected$marker';
    _c.value = TextEditingValue(
      text: sel.textBefore(text) + replaced + sel.textAfter(text),
      selection: selected.isEmpty
          ? TextSelection.collapsed(offset: sel.start + marker.length)
          : TextSelection(baseOffset: sel.start, extentOffset: sel.start + replaced.length),
    );
    _changed();
  }

  /// Toggles [prefix] at the start of the current line.
  void _prefixLine(String prefix) {
    final text = _c.text;
    final offset = _c.selection.isValid ? _c.selection.start : text.length;
    final lineStart = text.lastIndexOf('\n', offset == 0 ? 0 : offset - 1) + 1;
    final String next;
    final int cursor;
    if (text.startsWith(prefix, lineStart)) {
      next = text.replaceRange(lineStart, lineStart + prefix.length, '');
      cursor = (offset - prefix.length).clamp(lineStart, next.length);
    } else {
      next = text.replaceRange(lineStart, lineStart, prefix);
      cursor = offset + prefix.length;
    }
    _c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget tool(IconData icon, String tooltip, VoidCallback onPressed) =>
        IconButton(tooltip: tooltip, onPressed: _preview ? null : onPressed, icon: Icon(icon));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              tool(Icons.format_bold, l.tasksMdBold, () => _wrap('**')),
              tool(Icons.format_italic, l.tasksMdItalic, () => _wrap('*')),
              tool(Icons.title, l.tasksMdHeading, () => _prefixLine('# ')),
              tool(Icons.format_list_bulleted, l.tasksMdBullet, () => _prefixLine('- ')),
              tool(Icons.format_list_numbered, l.tasksMdNumbered, () => _prefixLine('1. ')),
              tool(Icons.check_box_outlined, l.tasksMdCheckbox, () => _prefixLine('- [ ] ')),
              tool(Icons.code, l.tasksMdCode, () => _wrap('`')),
              TextButton.icon(
                key: const ValueKey('notes-preview-toggle'),
                onPressed: () => setState(() => _preview = !_preview),
                icon: Icon(_preview ? Icons.edit_outlined : Icons.visibility_outlined),
                label: Text(_preview ? l.tasksNotesEdit : l.tasksNotesPreview),
              ),
            ],
          ),
        ),
        if (_preview)
          Container(
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.outlineVariant),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: MarkdownLiteView(_c.text),
          )
        else
          TextField(
            key: widget.fieldKey,
            controller: _c,
            minLines: 3,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(hintText: widget.hint ?? l.tasksNotesHint, border: const OutlineInputBorder()),
            onChanged: (_) => _changed(),
          ),
      ],
    );
  }
}
