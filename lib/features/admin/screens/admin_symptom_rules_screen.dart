import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class AdminSymptomRulesScreen extends StatelessWidget {
  const AdminSymptomRulesScreen({super.key});

  Future<void> seedDefaults(BuildContext context) async {
    try {
      await AppData.instance.seedDefaultSymptomRules();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default symptom rules added.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rules could not be added.')),
      );
    }
  }

  Future<void> deleteRule(
    BuildContext context,
    SymptomRuleModel rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete rule'),
          content: Text(
            'Delete the ${rule.department} symptom rule?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await AppData.instance.deleteSymptomRule(rule.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rule could not be deleted.')),
      );
    }
  }

  Future<void> showRuleDialog(
    BuildContext context, {
    SymptomRuleModel? rule,
  }) async {
    final symptomsController = TextEditingController(
      text: rule?.symptoms.join(', ') ?? '',
    );
    final departmentController = TextEditingController(
      text: rule?.department ?? '',
    );
    final adviceController = TextEditingController(
      text: rule?.advice ?? '',
    );
    var urgency = rule?.urgency ?? 'Routine';
    var enabled = rule?.enabled ?? true;
    var saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(rule == null ? 'Add Symptom Rule' : 'Edit Rule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: symptomsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Symptoms',
                        hintText: 'Chest pain, Fast heartbeat',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: urgency,
                      decoration: const InputDecoration(
                        labelText: 'Urgency',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Routine',
                          child: Text('Routine'),
                        ),
                        DropdownMenuItem(
                          value: 'Priority',
                          child: Text('Priority'),
                        ),
                        DropdownMenuItem(
                          value: 'Urgent',
                          child: Text('Urgent'),
                        ),
                        DropdownMenuItem(
                          value: 'Emergency',
                          child: Text('Emergency'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() {
                                urgency = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: adviceController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Health suggestion',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enabled'),
                      value: enabled,
                      onChanged: saving
                          ? null
                          : (value) {
                              setDialogState(() {
                                enabled = value;
                              });
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final symptoms = symptomsController.text
                              .split(',')
                              .map((item) => item.trim())
                              .where((item) => item.isNotEmpty)
                              .toList();
                          if (symptoms.isEmpty ||
                              departmentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter symptoms and a department.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });
                          try {
                            await AppData.instance.saveSymptomRule(
                              ruleId: rule?.id,
                              symptoms: symptoms,
                              department: departmentController.text,
                              urgency: urgency,
                              advice: adviceController.text,
                              enabled: enabled,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rule could not be saved.'),
                                ),
                              );
                            }
                            setDialogState(() {
                              saving = false;
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    symptomsController.dispose();
    departmentController.dispose();
    adviceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Rules'),
        actions: [
          IconButton(
            tooltip: 'Add rule',
            onPressed: () => showRuleDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final rules = appData.symptomRules;
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.rule_folder_outlined,
                      size: 54,
                      color: Colors.black45,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No database symptom rules exist. The patient app is using safe built-in defaults.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => seedDefaults(context),
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Add Default Rules'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.lightMint,
                          child: Icon(
                            Icons.psychology,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rule.department,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${rule.urgency} • ${rule.enabled ? 'Enabled' : 'Disabled'}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => showRuleDialog(
                            context,
                            rule: rule,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => deleteRule(context, rule),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rule.symptoms.join(', '),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (rule.advice.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        rule.advice,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showRuleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }
}
