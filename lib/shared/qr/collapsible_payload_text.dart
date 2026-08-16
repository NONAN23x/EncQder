import 'package:flutter/material.dart';

/// Selectable QR content that only expands when it exceeds three lines.
class CollapsiblePayloadText extends StatefulWidget {
  const CollapsiblePayloadText({super.key, required this.data, this.style});

  final String data;
  final TextStyle? style;

  @override
  State<CollapsiblePayloadText> createState() => _CollapsiblePayloadTextState();
}

class _CollapsiblePayloadTextState extends State<CollapsiblePayloadText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).textTheme.bodyMedium;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final painter = TextPainter(
          text: TextSpan(text: widget.data, style: style),
          maxLines: 3,
          textDirection: textDirection,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = painter.didExceedMaxLines;
        final expanded = _expanded && canExpand;

        return Semantics(
          button: canExpand,
          hint: canExpand
              ? expanded
                    ? 'Double tap to show a shortened preview'
                    : 'Double tap to show the full QR content'
              : null,
          child: Listener(
            key: const ValueKey('toggle-qr-payload'),
            behavior: HitTestBehavior.translucent,
            onPointerUp: canExpand
                ? (_) => setState(() => _expanded = !_expanded)
                : null,
            child: SelectionArea(
              child: Text(
                widget.data,
                maxLines: expanded ? null : 3,
                overflow: expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }
}
