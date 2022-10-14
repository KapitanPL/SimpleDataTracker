import 'package:flutter/material.dart';

Offset _position = const Offset(0, 0);

class ContextMenuWrapper<T> extends GestureDetector {
  ContextMenuWrapper(
      {Key? key,
      required Widget child,
      required BuildContext context,
      required List<PopupMenuItem<T>> items,
      required void Function(T?) itemCallback})
      : super(
            key: key,
            onTapDown: (details) {
              _position = details.globalPosition;
            },
            onLongPress: () {
              showMenu(
                      context: context,
                      position: RelativeRect.fromRect(
                          _position &
                              const Size(
                                  40, 40), // smaller rect, the touch area
                          Offset.zero &
                              MediaQuery.of(context)
                                  .size // Bigger rect, the entire screen
                          ),
                      items: items)
                  .then((value) => itemCallback(value));
            },
            child: child);
}
