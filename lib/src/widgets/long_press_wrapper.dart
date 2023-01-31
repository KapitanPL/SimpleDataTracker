import 'package:flutter/material.dart';

Offset _position = const Offset(0, 0);

class LongPressWrapper extends GestureDetector {
  LongPressWrapper(
      {Key? key,
      required Widget child,
      required void Function()? tapCallback,
      required BuildContext context,
      required void Function()? pressCallback})
      : super(
            key: key,
            onTapDown: (details) {
              _position = details.globalPosition;
            },
            onTapUp: (details) => tapCallback?.call(),
            onLongPress: pressCallback,
            child: child);
}
