import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/local_app_repository.dart';
import '../ui/features/home/home_shell.dart';
import '../ui/features/onboarding/onboarding_view.dart';
import '../ui/core/bule_design.dart';
import 'app_view_model.dart';

class BuleApp extends StatefulWidget {
  const BuleApp({super.key, required this.repository});
  final LocalAppRepository repository;

  @override
  State<BuleApp> createState() => _BuleAppState();
}

class _BuleAppState extends State<BuleApp> {
  late final AppViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = AppViewModel(widget.repository)..initialize();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoApp(
    title: 'Bule',
    debugShowCheckedModeBanner: false,
    theme: const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: CupertinoColors.activeGreen,
      scaffoldBackgroundColor: CupertinoColors.systemBackground,
    ),
    builder: (context, child) => kIsWeb
        ? BuleWideFrame(child: child ?? const SizedBox.shrink())
        : child ?? const SizedBox.shrink(),
    home: ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => switch (viewModel.loadState) {
        AppLoadState.loading => const CupertinoPageScaffold(
          child: SafeArea(child: Center(child: CupertinoActivityIndicator())),
        ),
        AppLoadState.failure => CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(middle: Text('Bule')),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    color: CupertinoColors.destructiveRed,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  const Text('Could not load offline lessons.'),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: viewModel.initialize,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
        AppLoadState.ready =>
          viewModel.preferences.hasCompletedOnboarding
              ? HomeShell(viewModel: viewModel)
              : OnboardingView(viewModel: viewModel),
      },
    ),
  );
}
