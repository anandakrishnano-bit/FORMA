import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/components/exercise_card.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/search_field.dart';
import 'package:forma/core/components/section_header.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/exercise_model.dart';
import 'package:forma/data/repositories/discovery_repository.dart';

class ExerciseDiscoveryModal extends ConsumerStatefulWidget {
  final ValueChanged<ExerciseModel>? onSelectExercise;

  const ExerciseDiscoveryModal({super.key, this.onSelectExercise});

  @override
  ConsumerState<ExerciseDiscoveryModal> createState() =>
      _ExerciseDiscoveryModalState();
}

class _ExerciseDiscoveryModalState
    extends ConsumerState<ExerciseDiscoveryModal> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(exerciseDiscoveryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FormaColors.concreteGrey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Exercise Discovery',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 14),

          // Search Field
          FormaSearchField(
            controller: _controller,
            hintText: 'Search any exercise (e.g. Bench, Squat, RDL)...',
            onChanged: (val) {
              setState(() {});
              if (val.trim().isNotEmpty) {
                ref.read(exerciseDiscoveryProvider.notifier).search(val);
              }
            },
          ),

          const SizedBox(height: 14),

          if (_controller.text.trim().isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                ref
                    .read(exerciseDiscoveryProvider.notifier)
                    .triggerOnlineSearch(_controller.text.trim());
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color:
                      isDark ? FormaColors.azureDark : FormaColors.azurePastel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: FormaColors.azure.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 18, color: FormaColors.azure),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search sports science library for "${_controller.text.trim()}"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FormaColors.azure,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: FormaColors.azure),
                  ],
                ),
              ),
            ),
          ],

          // State Status / Results
          if (state.status == DiscoveryStatus.searching)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          FormaColors.primaryAccent),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Searching for results...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (state.status == DiscoveryStatus.notFound)
            Expanded(
              child: Center(
                child: Text(
                  state.statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
              ),
            )
          else ...[
            if (state.internalResults.isNotEmpty) ...[
              const FormaSectionHeader(title: 'From FORMA Catalogue'),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: state.internalResults.length,
                  itemBuilder: (context, idx) {
                    final ex = state.internalResults[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ExerciseCard(
                        exercise: ex,
                        onTap: () {
                          widget.onSelectExercise?.call(ex);
                          Navigator.of(context).pop(ex);
                        },
                      ),
                    );
                  },
                ),
              ),
            ] else if (state.discoveredResults.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const FormaSectionHeader(title: 'Discovered Results'),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'New Item',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FormaColors.goldenYellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: state.discoveredResults.length,
                  itemBuilder: (context, idx) {
                    final ex = state.discoveredResults[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? FormaColors.darkCardBackground
                            : FormaColors.lightCardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: FormaColors.primaryAccent
                                .withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ex.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? FormaColors.darkPrimaryText
                                        : FormaColors.lightPrimaryText,
                                  ),
                                ),
                              ),
                              Text(
                                ex.primaryMuscle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: FormaColors.goldenYellow,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ex.instructions,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? FormaColors.darkSecondaryText
                                  : FormaColors.lightSecondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FormaButton(
                                label: 'Save to Catalogue',
                                onPressed: () {
                                  ref
                                      .read(exerciseDiscoveryProvider.notifier)
                                      .approveAndSaveExercise(ex);
                                  widget.onSelectExercise?.call(ex);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Added "${ex.name}" to FORMA catalogue!')),
                                  );
                                  Navigator.of(context).pop(ex);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Type 3+ letters to search...'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
