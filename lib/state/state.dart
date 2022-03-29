import 'dart:async';

import 'package:flutter/material.dart';

abstract class UIState<T extends StatefulWidget> extends State<T> {
  bool _closed = false;
  bool get isClosed => _closed;
  bool get isNotClosed => !_closed;

  bool enabled = true;
  bool get disabled => !enabled;
  set disabled(bool ok) {
    enabled = !ok;
  }

  List<StreamSubscription>? _subscriptions;
  List<StreamSubscription> _getSubscriptions() {
    return _subscriptions ??= <StreamSubscription>[];
  }

  List<VoidCallback>? _dispose;
  List<VoidCallback> _getDispose() {
    return _dispose ??= <VoidCallback>[];
  }

  @protected
  void checkAlive() {
    if (isClosed) {
      throw Exception('wiget already closed');
    }
  }

  @protected
  void aliveSetState(VoidCallback fn) {
    if (isNotClosed) {
      setState(fn);
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    _closed = true;
    if (_subscriptions != null) {
      for (var subscription in _subscriptions!) {
        subscription.cancel();
      }
    }
    if (_dispose != null) {
      for (var f in _dispose!) {
        f();
      }
    }
    super.dispose();
  }

  @protected
  void addSubscription(StreamSubscription subscription) {
    _getSubscriptions().add(subscription);
  }

  @protected
  void addAllSubscription(Iterable<StreamSubscription> subscriptions) {
    _getSubscriptions().addAll(subscriptions);
  }

  @protected
  void addDispose(VoidCallback dispose) {
    _getDispose().add(dispose);
  }

  @protected
  void addAllDispose(Iterable<VoidCallback> disposes) {
    _getDispose().addAll(disposes);
  }
}
