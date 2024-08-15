import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String subText;
  final String text;
  final TextStyle? style;
  final TextOverflow? overflow;

  const HighlightedText(
    this.text, {
    super.key,
    required this.subText,
    this.style,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final splitText = _splitTextPerSubText(text, subText);

    return RichText(
      overflow: overflow ?? TextOverflow.ellipsis,
      text: TextSpan(
        children: splitText.map(
          (e) {
            final text = e.$1;
            final selected = e.$2;

            return TextSpan(
              text: text,
              style: (style ?? DefaultTextStyle.of(context).style).copyWith(
                backgroundColor: selected ? Colors.yellow : null,
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  /// (subString, isSelected)
  List<(String, bool)> _splitTextPerSubText(String text, String subText) {
    if (text.isEmpty) {
      return [(text, false)];
    }

    if (subText.isEmpty) {
      return [(text, false)];
    }

    final formattedText = text.toLowerCase();
    final formattedSubText = subText.toLowerCase();
    final result = <(String, bool)>[];

    var startIndex = 0;

    late int subStringIndex;
    while (true) {
      subStringIndex = formattedText.indexOf(formattedSubText, startIndex);
      if (subStringIndex == -1) {
        if (startIndex < formattedText.length) {
          final unselectedSubString = text.substring(startIndex);
          result.add((unselectedSubString, false));
        }

        break;
      }

      if (subStringIndex != startIndex) {
        final unselectedSubString = text.substring(startIndex, subStringIndex);
        result.add((unselectedSubString, false));
        startIndex = subStringIndex;
      }

      final selectedSubString = text.substring(subStringIndex, subStringIndex + formattedSubText.length);

      result.add((selectedSubString, true));
      startIndex = subStringIndex + formattedSubText.length;
    }

    return result;
  }
}
