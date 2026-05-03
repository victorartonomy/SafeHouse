import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../auth/presentation/pages/splash_screen.dart';
import '../bloc/calculator_bloc.dart';
import '../bloc/calculator_event.dart';
import '../bloc/calculator_state.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_keypad.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const CalculatorScreen());

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final googleTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: const Color(0xFF4285F4),
    );

    return BlocProvider<CalculatorBloc>(
      create: (_) => di.sl<CalculatorBloc>(),
      child: Theme(
        data: googleTheme,
        child: Builder(
          builder: (innerContext) {
            return BlocListener<CalculatorBloc, CalculatorState>(
              listenWhen: (prev, curr) => !prev.unlocked && curr.unlocked,
              listener: (context, state) {
                Navigator.of(context).pushAndRemoveUntil(
                  SplashScreen.route(),
                  (_) => false,
                );
              },
              child: _CalculatorBody(theme: Theme.of(innerContext)),
            );
          },
        ),
      ),
    );
  }
}

class _CalculatorBody extends StatelessWidget {
  final ThemeData theme;
  const _CalculatorBody({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final maxWidth = isWide ? 560.0 : double.infinity;
            final padding = isWide ? 32.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      BlocBuilder<CalculatorBloc, CalculatorState>(
                        buildWhen: (p, c) => p.display != c.display,
                        builder: (context, state) =>
                            CalculatorDisplay(value: state.display),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: CalculatorKeypad(
                            onKey: (k) => _dispatch(context, k),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _dispatch(BuildContext context, CalcKey key) {
    final bloc = context.read<CalculatorBloc>();
    switch (key.label) {
      case 'C':
        bloc.add(const CalculatorClearPressed());
      case '⌫':
        bloc.add(const CalculatorBackspacePressed());
      case '=':
        bloc.add(const CalculatorEqualsPressed());
      default:
        bloc.add(CalculatorKeyPressed(key.label));
    }
  }
}
