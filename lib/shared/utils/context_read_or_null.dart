import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Like `context.read<T>()` but returns `null` when no provider of `T`
/// exists above this context — used by screens that are also pumped
/// standalone in widget tests (without the app-root provider stack).
extension BuildContextReadOrNull on BuildContext {
  T? readOrNull<T>() {
    try {
      return read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}