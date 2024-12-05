import 'dart:async';
import 'package:bruss/api.dart';
import 'package:bruss/settings/init.dart';
import 'package:bruss/ui/pages/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorHandler {
  static final Completer<void> _completer = Completer<void>();
  static BuildContext? _context;

  static void onFlutterError(FlutterErrorDetails details) {
    print("====== onFlutterError ======");
    _completer.future.then((_) {
      print('FlutterError: ${details.exception}');
      print('FlutterError: ${details.stack}');
    });
  }

  static Widget genericError(BuildContext context, Object error, StackTrace stack) {
    return AlertDialog(
      title: const Text("Error"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error.toString()),
          Text(stack.toString()),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }

  static void onPlatformError(Object error, StackTrace stack) {
    if (kDebugMode) {
      print("====== onPlatformErrro - error ======");
      print(error);
      print("====== onPlatformError - stack ======");
      print(stack);
      print("=====================================");
    }

    _completer.future.then((_) {
      if (error is ApiException) {
        showDialog(
          context: _context!,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Center(child: Text("Fatal Error while connecting to API")),
              content: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.error.toString()),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    child: Text(stack.toString() + "\nCaused by:\n" + error.stack.toString()),
                  ),
                  const Text("Please check your internet connection or change the API URL using the button below. The app won't work without a valid API connection."),
                ],
              )),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    const key = "api.url";
                    if (context.mounted) {
                      showSettingDialog(
                        context,
                        key,
                        await Settings().get(key),
                        (context, field) async {
                          await Settings().set(key, field.controller!.text);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        (context) {
                          Navigator.of(context).pop();
                        }
                      );
                    }
                  },
                  child: const Text("Edit API"),
                ),
                if  (error.retry != null) ElevatedButton(
                  child: const Text("Retry"),
                  onPressed: () {
                    error.retry!();
                    Navigator.of(context).pop();
                  }
                ),
                // ElevatedButton(
                //   child: const Text("Restart"),
                //   onPressed: () 
                // )
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text("Exit"),
                ),
              ]
            );
          });
      } else {
        showDialog(context: _context!, builder: (context) {
          return ErrorHandler.genericError(context, error, stack);
        });
      }
    });
  }

  static void registerContext(BuildContext context) {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
    _context = context;
  }
}

class FutureBuilderError extends StatelessWidget {
  final String message;
  final Object error;
  final StackTrace stack;
  final VoidCallback onRetry;

  const FutureBuilderError(this.message, this.onRetry, this.error, this.stack);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh), 
                onPressed: onRetry,
                label: Text("Retry")
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.bug_report), 
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Error details"),
                              Text(error.toString()),
                              Text(stack.toString()),
                            ],
                          ),
                        ),
                      );
                    }
                  );
                },
                label: Text("Details")
              ),
            ],
          ),
        ),
      ),
    );
  }
}
