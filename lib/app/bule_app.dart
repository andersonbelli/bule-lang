import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/local_app_repository.dart';
import '../domain/services/speech_reader.dart';
import '../ui/features/home/home_shell.dart';
import '../ui/features/onboarding/onboarding_view.dart';
import '../ui/features/onboarding/placement_view.dart';
import '../ui/core/bule_design.dart';
import 'app_view_model.dart';

class BuleApp extends StatefulWidget {
  const BuleApp({
    super.key,
    required this.repository,
    required this.speechReader,
  });
  final LocalAppRepository repository;
  final SpeechReader speechReader;

  @override
  State<BuleApp> createState() => _BuleAppState();
}

class _BuleAppState extends State<BuleApp> {
  late final AppViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = AppViewModel(widget.repository, widget.speechReader)
      ..initialize();
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
        AppLoadState.loading => CupertinoPageScaffold(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🫖', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 16),
                  const Text(
                    'Bule',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn a little every day',
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CupertinoActivityIndicator(radius: 12),
                ],
              ),
            ),
          ),
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
          !viewModel.preferences.hasCompletedOnboarding
              ? OnboardingView(viewModel: viewModel)
              : viewModel.preferences.placementLevel == null
              ? PlacementView(viewModel: viewModel)
              : HomeShell(viewModel: viewModel),
      },
    ),
  );
}
