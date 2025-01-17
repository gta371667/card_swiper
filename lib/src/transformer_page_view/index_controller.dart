import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class IndexControllerEventBase {
  final bool animation;

  final completer = Completer<void>();

  Future<void> get future => completer.future;

  void complete() {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  IndexControllerEventBase({
    required this.animation,
  });
}

mixin TargetedPositionControllerEvent on IndexControllerEventBase {
  double get targetPosition;
}
mixin StepBasedIndexControllerEvent on TargetedPositionControllerEvent {
  int get step;

  int calcNextIndex({
    required int currentIndex,
    required int itemCount,
    required bool loop,
    required bool reverse,
  }) {
    // 修正prev、next錯誤
    final s = step < 0 ? 2 : -2;
    final indexOffset = itemCount > 2 ? s : 0;

    var cIndex = currentIndex;
    if (reverse) {
      cIndex -= (step + indexOffset);
    } else {
      cIndex += (step + indexOffset);
    }

    if (!loop) {
      if (cIndex >= itemCount) {
        cIndex = 0;
      } else if (cIndex < 0) {
        cIndex = itemCount - 1;
      }
    }
    return cIndex;
  }
}

class NextIndexControllerEvent extends IndexControllerEventBase
    with TargetedPositionControllerEvent, StepBasedIndexControllerEvent {
  NextIndexControllerEvent({
    required bool animation,
  }) : super(
          animation: animation,
        );

  @override
  int get step => 1;

  @override
  double get targetPosition => 1;
}

class PrevIndexControllerEvent extends IndexControllerEventBase
    with TargetedPositionControllerEvent, StepBasedIndexControllerEvent {
  PrevIndexControllerEvent({
    required bool animation,
  }) : super(
          animation: animation,
        );

  @override
  int get step => -1;

  @override
  double get targetPosition => 0;
}

class MoveIndexControllerEvent extends IndexControllerEventBase with TargetedPositionControllerEvent {
  final int newIndex;
  final int oldIndex;

  MoveIndexControllerEvent({
    required this.newIndex,
    required this.oldIndex,
    required bool animation,
  }) : super(
          animation: animation,
        );

  @override
  double get targetPosition => newIndex > oldIndex ? 1 : 0;
}

class IndexController extends ChangeNotifier {
  final bool reversedMove;

  IndexControllerEventBase? event;
  int index = 0;

  IndexController({required this.reversedMove});

  Future move(int index, {bool animation = true}) {
    final e = event = MoveIndexControllerEvent(
      animation: animation,
      newIndex: index,
      oldIndex: this.index,
    );
    notifyListeners();
    return e.future;
  }

  Future next({bool animation = true}) {
    // 因有調整calcNextIndex，造成切換變成倒敘，故跟previous對換
    if (reversedMove) {
      event = PrevIndexControllerEvent(animation: animation);
    } else {
      event = NextIndexControllerEvent(animation: animation);
    }
    // final e = event = NextIndexControllerEvent(animation: animation);
    notifyListeners();
    return event!.future;
  }

  Future previous({bool animation = true}) {
    // 因有調整calcNextIndex，造成切換變成倒敘，故跟previous對換
    if (reversedMove) {
      event = NextIndexControllerEvent(animation: animation);
    } else {
      event = PrevIndexControllerEvent(animation: animation);
    }
    // final e = event = PrevIndexControllerEvent(animation: animation);
    notifyListeners();
    return event!.future;
  }
}
