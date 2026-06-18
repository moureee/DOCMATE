import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({
    super.key,
    required this.doctor,
  });

  final DoctorModel doctor;

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  late Map<int, DoctorDaySchedule> schedule;
  bool saving = false;

  static const dayNames = <int, String>{
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    schedule = <int, DoctorDaySchedule>{
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        day: widget.doctor.weeklySchedule[day] ??
            const DoctorDaySchedule(
              enabled: false,
              startTime: '09:00 AM',
              endTime: '05:00 PM',
              slotMinutes: 30,
            ),
    };
  }

  Future<void> pickTime(int weekday, bool isStart) async {
    final current = schedule[weekday]!;
    final initial = _parseTime(isStart ? current.startTime : current.endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;

    setState(() {
      schedule[weekday] = DoctorDaySchedule(
        enabled: current.enabled,
        startTime: isStart ? picked.format(context) : current.startTime,
        endTime: isStart ? current.endTime : picked.format(context),
        slotMinutes: current.slotMinutes,
      );
    });
  }

  TimeOfDay _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return const TimeOfDay(hour: 9, minute: 0);
    var hour = int.tryParse(match.group(1) ?? '') ?? 9;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = (match.group(3) ?? 'AM').toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> saveSchedule() async {
    setState(() => saving = true);
    try {
      await AppData.instance.saveWeeklySchedule(widget.doctor.id, schedule);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly schedule saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the weekly schedule.')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> addException() async {
    var selectedDate = DateTime.now().add(const Duration(days: 1));
    var unavailable = true;
    final timesController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule Exception'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: Text(formatDate(selectedDate)),
                      subtitle: const Text('Tap to choose date'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Unavailable all day'),
                      subtitle: const Text(
                        'Use this for leave, vacation or a closed clinic.',
                      ),
                      value: unavailable,
                      onChanged: (value) {
                        setDialogState(() => unavailable = value);
                      },
                    ),
                    if (!unavailable)
                      TextField(
                        controller: timesController,
                        decoration: const InputDecoration(
                          labelText: 'Custom times',
                          hintText: '09:00 AM, 09:30 AM, 10:00 AM',
                          helperText:
                              'Separate each appointment time by comma.',
                        ),
                        maxLines: 2,
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Reason or note (optional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final customTimes = timesController.text
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .toList();
                    if (!unavailable && customTimes.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Enter at least one custom time.'),
                        ),
                      );
                      return;
                    }
                    await AppData.instance.saveScheduleException(
                      doctorId: widget.doctor.id,
                      date: selectedDate,
                      unavailable: unavailable,
                      customTimes: customTimes,
                      note: noteController.text,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    timesController.dispose();
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Availability')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addException,
        icon: const Icon(Icons.event_busy),
        label: const Text('Add Exception'),
      ),
      body: AnimatedBuilder(
        animation: AppData.instance,
        builder: (context, child) {
          final liveDoctor = AppData.instance.doctors.firstWhere(
            (item) => item.id == widget.doctor.id,
            orElse: () => widget.doctor,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Set your normal weekly working hours once. Patients will '
                  'receive appointment slots automatically. Add an exception '
                  'only when you are unavailable or working different hours.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 18),
              ...dayNames.entries
                  .map((entry) => _dayCard(entry.key, entry.value)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : saveSchedule,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(saving ? 'Saving...' : 'Save Weekly Schedule'),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Schedule Exceptions',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (liveDoctor.scheduleExceptions.isEmpty)
                const Text(
                  'No exceptions added. Your normal weekly schedule applies.',
                  style: TextStyle(color: Colors.black54),
                )
              else
                ...liveDoctor.scheduleExceptions.entries.map((entry) {
                  final value = entry.value;
                  final key = entry.key;
                  final date = key.length == 8
                      ? DateTime.tryParse(
                          '${key.substring(0, 4)}-${key.substring(4, 6)}-${key.substring(6, 8)}',
                        )
                      : null;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        value.unavailable
                            ? Icons.event_busy
                            : Icons.edit_calendar,
                        color: value.unavailable
                            ? AppColors.danger
                            : AppColors.primaryDark,
                      ),
                      title: Text(date == null ? key : formatDate(date)),
                      subtitle: Text(
                        value.unavailable
                            ? 'Unavailable all day${value.note.isEmpty ? '' : ' • ${value.note}'}'
                            : 'Custom times: ${value.customTimes.join(', ')}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove exception',
                        onPressed: date == null
                            ? null
                            : () => AppData.instance.removeScheduleException(
                                  widget.doctor.id,
                                  date,
                                ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                }),
              if (liveDoctor.availableSlots.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Legacy One-off Slots',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...liveDoctor.availableSlots.map(
                  (slot) => Card(
                    child: ListTile(
                      title: Text(availabilitySlotLabel(slot)),
                      trailing: IconButton(
                        onPressed: () => AppData.instance.removeAvailability(
                          widget.doctor.id,
                          slot,
                        ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _dayCard(int weekday, String name) {
    final current = schedule[weekday]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                current.enabled
                    ? '${current.startTime}–${current.endTime} • every ${current.slotMinutes} min'
                    : 'Not available',
              ),
              value: current.enabled,
              onChanged: (value) {
                setState(() {
                  schedule[weekday] = DoctorDaySchedule(
                    enabled: value,
                    startTime: current.startTime,
                    endTime: current.endTime,
                    slotMinutes: current.slotMinutes,
                  );
                });
              },
            ),
            if (current.enabled)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pickTime(weekday, true),
                      icon: const Icon(Icons.login),
                      label: Text(current.startTime),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pickTime(weekday, false),
                      icon: const Icon(Icons.logout),
                      label: Text(current.endTime),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: current.slotMinutes,
                    items: const [15, 20, 30, 45, 60]
                        .map(
                          (minutes) => DropdownMenuItem<int>(
                            value: minutes,
                            child: Text('$minutes m'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        schedule[weekday] = DoctorDaySchedule(
                          enabled: current.enabled,
                          startTime: current.startTime,
                          endTime: current.endTime,
                          slotMinutes: value,
                        );
                      });
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
