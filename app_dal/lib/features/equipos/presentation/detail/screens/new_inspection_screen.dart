import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/models/foim_question.dart';
import 'package:app_dal/features/equipos/repositories/foim_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewInspectionScreen extends StatefulWidget {
  const NewInspectionScreen({super.key, required this.equipo});

  final Equipo equipo;

  @override
  State<NewInspectionScreen> createState() => _NewInspectionScreenState();
}

class _NewInspectionScreenState extends State<NewInspectionScreen> {
  final FoimRepository _repository = FoimRepository();
  late Future<List<FoimQuestion>> _future;
  final Map<int, String> _answers = {}; // questionId -> "B" | "M"
  final Map<int, TextEditingController> _noteControllers = {};
  int _currentIndex = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchQuestions();
  }

  @override
  void dispose() {
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int questionId) {
    return _noteControllers.putIfAbsent(
      questionId,
      () => TextEditingController(),
    );
  }

  List<FoimQuestion> _filterForEquipo(List<FoimQuestion> questions) {
    final typeName = widget.equipo.type.name.toLowerCase();
    final isLpg = typeName.contains('lpg');
    final isElc = typeName.contains('elc');

    if (isLpg) {
      return questions
          .where((q) => q.target == 0 || q.target == 1)
          .toList(growable: false);
    }
    if (isElc) {
      return questions
          .where((q) => q.target == 0 || q.target == 2)
          .toList(growable: false);
    }
    return questions;
  }

  Future<void> _handleNext(List<FoimQuestion> questions) async {
    final current = questions[_currentIndex];
    final selected = _answers[current.id];
    final note = _controllerFor(current.id).text.trim();
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona Bien o Mal para continuar')),
      );
      return;
    }

    if (selected == 'M' && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega observaciones cuando marques "Mal"')),
      );
      return;
    }

    final isLast = _currentIndex == questions.length - 1;
    if (isLast) {
      await _submit(questions);
    } else {
      setState(() {
        _currentIndex += 1;
      });
    }
  }

  Future<void> _submit(List<FoimQuestion> questions) async {
    final user = context.read<AuthProvider>().state.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el usuario actual')),
      );
      return;
    }

    // Ensure every question is answered.
    final unanswered = questions.where((q) => !_answers.containsKey(q.id));
    if (unanswered.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Responde todas las preguntas antes de enviar')),
      );
      return;
    }

    final answers = questions
        .map(
          (q) => Foim03Answer(
            questionId: q.id,
            answer: _answers[q.id] ?? 'B',
            description: _controllerFor(q.id).text.trim(),
          ),
        )
        .toList(growable: false);

    setState(() {
      _submitting = true;
    });

    try {
      await _repository.createFoim03(
        equipmentId: widget.equipo.id,
        appUserId: user.id,
        dateCreated: DateTime.now(),
        answers: answers,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspección creada')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva inspección'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<FoimQuestion>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorView(
                  message: snapshot.error.toString(),
                  onRetry: () {
                    setState(() {
                      _future = _repository.fetchQuestions();
                    });
                  },
                );
              }

              final filtered = _filterForEquipo(snapshot.data ?? const []);
              if (filtered.isEmpty) {
                return _EmptyView(onRetry: () {
                  setState(() {
                    _future = _repository.fetchQuestions();
                  });
                });
              }

              final current = filtered[_currentIndex];
              final total = filtered.length;
              final controller = _controllerFor(current.id);
              final selected = _answers[current.id];
              final isLast = _currentIndex == total - 1;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Pregunta ${_currentIndex + 1} de $total',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.equipo.type.name,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      current.functionLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current.question,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _AnswerButton(
                                    label: 'Bien',
                                    isSelected: selected == 'B',
                                    onTap: _submitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _answers[current.id] = 'B';
                                            });
                                            _handleNext(filtered);
                                          },
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AnswerButton(
                                    label: 'Mal',
                                    isSelected: selected == 'M',
                                    onTap: _submitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _answers[current.id] = 'M';
                                            });
                                          },
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Observaciones (opcional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: _submitting || _currentIndex == 0
                              ? null
                              : () {
                                  setState(() {
                                    _currentIndex -= 1;
                                  });
                                },
                          child: const Text('Anterior'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _submitting
                              ? null
                              : () {
                                  _handleNext(filtered);
                                },
                          child: Text(isLast ? 'Enviar inspección' : 'Siguiente'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (_submitting)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected ? color : scheme.outlineVariant,
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isSelected ? color : scheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline, size: 64),
          const SizedBox(height: 8),
          const Text('No hay preguntas disponibles'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
