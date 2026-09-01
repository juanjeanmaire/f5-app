import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../matches/domain/match.dart';
import '../data/match_calls_repository.dart';
import 'match_calls_controller.dart';

class CreateMatchCallScreen extends ConsumerStatefulWidget {
  const CreateMatchCallScreen({super.key, required this.groupId, this.groupVenueAddress});

  final String groupId;
  final String? groupVenueAddress;

  @override
  ConsumerState<CreateMatchCallScreen> createState() => _CreateMatchCallScreenState();
}

class _CreateMatchCallScreenState extends ConsumerState<CreateMatchCallScreen> {
  MatchType _matchType = MatchType.f5;
  DateTime? _date;
  TimeOfDay? _time;
  bool _useGroupVenue = true;
  final _customVenueController = TextEditingController();
  final _commentController = TextEditingController();
  bool _submitting = false;

  bool get _groupHasVenue =>
      widget.groupVenueAddress != null && widget.groupVenueAddress!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _useGroupVenue = _groupHasVenue;
  }

  @override
  void dispose() {
    _customVenueController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí la fecha y el horario del partido')),
      );
      return;
    }

    final venue = _useGroupVenue ? widget.groupVenueAddress : _customVenueController.text.trim();
    if (venue == null || venue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indicá en qué cancha se juega')),
      );
      return;
    }

    final dateTime = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

    setState(() => _submitting = true);
    try {
      final repo = ref.read(matchCallsRepositoryProvider);
      await repo.create(
        widget.groupId,
        matchType: _matchType,
        date: dateTime,
        venueAddress: venue,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      ref.invalidate(activeMatchCallProvider(widget.groupId));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? 'Elegir fecha'
        : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}';
    final timeLabel = _time == null ? 'Elegir horario' : _time!.format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Realizar una convocatoria')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tipo de partido', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<MatchType>(
              segments: MatchType.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.toJson())))
                  .toList(),
              selected: {_matchType},
              onSelectionChanged: (s) => setState(() => _matchType = s.first),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(dateLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(timeLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Cancha', style: Theme.of(context).textTheme.titleMedium),
            if (_groupHasVenue) ...[
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                title: Text('La del grupo (${widget.groupVenueAddress})'),
                value: true,
                groupValue: _useGroupVenue,
                onChanged: (v) => setState(() => _useGroupVenue = v ?? true),
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Otra'),
                value: false,
                groupValue: _useGroupVenue,
                onChanged: (v) => setState(() => _useGroupVenue = v ?? false),
              ),
            ],
            if (!_useGroupVenue || !_groupHasVenue)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _customVenueController,
                  decoration: const InputDecoration(hintText: 'Dirección de la cancha'),
                ),
              ),
            const SizedBox(height: 20),
            Text('Comentario (opcional)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: llevar pechera, se paga por partido...',
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('LANZAR CONVOCATORIA'),
            ),
          ],
        ),
      ),
    );
  }
}
