import 'package:flutter/material.dart';

class ExpandableTextCard extends StatefulWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const ExpandableTextCard({
    super.key,
    required this.text,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<ExpandableTextCard> createState() => _ExpandableTextCardState();
}

class _ExpandableTextCardState extends State<ExpandableTextCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: widget.padding,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color
                : Colors.transparent,
          ),
        ),
        child: _isExpanded
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: SingleChildScrollView(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _isExpanded = false;
                      });
                    },
                    child: Text(
                      widget.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              )
            : Text(
                widget.text,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
