import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../data/elo_config_repository.dart';
import '../domain/elo_config.dart';

class EloConfigScreen extends ConsumerStatefulWidget {
  const EloConfigScreen({super.key, required this.groupId, required this.isAdmin});

  final String groupId;
  final bool isAdmin;

  @override
  ConsumerState<EloConfigScreen> createState() => _EloConfigScreenState();
}

class _EloConfigScreenState extends ConsumerState<EloConfigScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  bool _initialized = false;

  void _initControllers(EloConfig config) {
    if (_initialized) return;
    _controllers['kFactorNew'] = TextEditingController(text: config.kFactorNew.toStringAsFixed(0));
    _controllers['kFactorMid'] = TextEditingController(text: config.kFactorMid.toStringAsFixed(0));
    _controllers['kFactorVeteran'] =
        TextEditingController(text: config.kFactorVeteran.toStringAsFixed(0));
    _controllers['newThreshold'] = TextEditingController(text: '${config.newThreshold}');
    _controllers['veteranThreshold'] = TextEditingController(text: '${config.veteranThreshold}');
    _controllers['goalDiffWeight'] =
        TextEditingController(text: config.goalDiffWeight.toStringAsFixed(2));
    _controllers['maxGoalDiffMultiplier'] =
        TextEditingController(text: config.maxGoalDiffMultiplier.toStringAsFixed(2));
    _initialized = true;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(eloConfigRepositoryProvider);
      await repo.updateEloConfig(widget.groupId, {
        'kFactorNew': double.parse(_controllers['kFactorNew']!.text),
        'kFactorMid': double.parse(_controllers['kFactorMid']!.text),
        'kFactorVeteran': double.parse(_controllers['kFactorVeteran']!.text),
        'newThreshold': int.parse(_controllers['newThreshold']!.text),
        'veteranThreshold': int.parse(_controllers['veteranThreshold']!.text),
        'goalDiffWeight': double.parse(_controllers['goalDiffWeight']!.text),
        'maxGoalDiffMultiplier': double.parse(_controllers['maxGoalDiffMultiplier']!.text),
      });
      ref.invalidate(eloConfigProvider(widget.groupId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Configuración guardada')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Revisá que todos los valores sean números válidos')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(eloConfigProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de ELO')),
      body: AsyncValueWidget<EloConfig>(
        value: configAsync,
        onRetry: () => ref.invalidate(eloConfigProvider(widget.groupId)),
        data: (config) {
          _initControllers(config);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.isAdmin
                    ? 'Ajustá cómo se calcula el ELO en este grupo.'
                    : 'Así se calcula el ELO en este grupo (solo un capitán puede editarlo).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('K-factor (velocidad de ajuste según experiencia)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              _NumberField(
                label: 'Jugador nuevo',
                controller: _controllers['kFactorNew']!,
                enabled: widget.isAdmin,
              ),
              _NumberField(
                label: 'Jugador intermedio',
                controller: _controllers['kFactorMid']!,
                enabled: widget.isAdmin,
              ),
              _NumberField(
                label: 'Jugador veterano',
                controller: _controllers['kFactorVeteran']!,
                enabled: widget.isAdmin,
              ),
              const SizedBox(height: 16),
              Text('Umbrales de experiencia (cantidad de partidos)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              _NumberField(
                label: 'Deja de ser "nuevo" a partir de',
                controller: _controllers['newThreshold']!,
                enabled: widget.isAdmin,
              ),
              _NumberField(
                label: 'Pasa a ser "veterano" a partir de',
                controller: _controllers['veteranThreshold']!,
                enabled: widget.isAdmin,
              ),
              const SizedBox(height: 16),
              Text('Diferencia de gol', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              _NumberField(
                label: 'Peso de la diferencia de gol',
                controller: _controllers['goalDiffWeight']!,
                enabled: widget.isAdmin,
                decimal: true,
              ),
              _NumberField(
                label: 'Multiplicador máximo por goleada',
                controller: _controllers['maxGoalDiffMultiplier']!,
                enabled: widget.isAdmin,
                decimal: true,
              ),
              if (widget.isAdmin) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.decimal = false,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
