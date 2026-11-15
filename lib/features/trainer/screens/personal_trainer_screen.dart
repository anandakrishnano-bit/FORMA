import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/trainer_message_model.dart';
import 'package:forma/data/repositories/personal_trainer_repository.dart';

class PersonalTrainerScreen extends ConsumerStatefulWidget {
  const PersonalTrainerScreen({super.key});

  @override
  ConsumerState<PersonalTrainerScreen> createState() =>
      _PersonalTrainerScreenState();
}

class _PersonalTrainerScreenState extends ConsumerState<PersonalTrainerScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _quickSuggestions = [
    'Help me plan my next workout.',
    'Explain an exercise.',
    'Suggest an alternative exercise.',
    'Help me understand my progress.',
    'Answer a nutrition question.',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.positions.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trainerState = ref.watch(personalTrainerProvider);

    ref.listen<PersonalTrainerState>(personalTrainerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Home',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: const Text(
            'Personal Trainer',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Trainer Settings',
            icon: const Icon(Icons.tune_rounded, size: 20),
            onPressed: () => context.push('/user-api-key-settings'),
          ),
          IconButton(
            tooltip: 'New Conversation',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ref.read(personalTrainerProvider.notifier).startNewConversation();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Messages View Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: trainerState.messages.length +
                    (trainerState.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == trainerState.messages.length &&
                      trainerState.isLoading) {
                    return _buildLoadingBubble(isDark);
                  }

                  final msg = trainerState.messages[index];
                  final isUser = msg.sender == MessageSender.user;

                  return _buildMessageBubble(msg, isUser, isDark);
                },
              ),
            ),

            // 2. Quick Suggested Questions Carousel (shown when conversation is new)
            if (trainerState.messages.length <= 1 && !trainerState.isLoading)
              Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickSuggestions.length,
                  itemBuilder: (context, idx) {
                    final suggestion = _quickSuggestions[idx];
                    return GestureDetector(
                      onTap: () {
                        _inputController.text = suggestion;
                        _sendMessage();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? FormaColors.darkCardBackground
                              : FormaColors.lightCardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: FormaColors.primaryAccent
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? FormaColors.darkPrimaryText
                                : FormaColors.lightPrimaryText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 3. Bottom Text Input Field (Fixed with adjustResize keyboard support)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? FormaColors.darkCardBackground : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? FormaColors.darkSecondaryBackground
                            : FormaColors.lightSecondaryBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _inputController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? FormaColors.darkPrimaryText
                              : FormaColors.lightPrimaryText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask about exercises, routines, food...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: FormaColors.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded,
                            size: 20, color: FormaColors.charcoal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildMessageBubble(TrainerMessage msg, bool isUser, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? FormaColors.primaryAccent
              : msg.isError
                  ? FormaColors.coralPink.withValues(alpha: 0.2)
                  : (isDark ? FormaColors.charcoal : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: !isUser && !msg.isError
              ? Border.all(
                  color: FormaColors.primaryAccent.withValues(alpha: 0.2))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && msg.isPersonalDataBased) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 12, color: FormaColors.goldenYellow),
                    SizedBox(width: 4),
                    Text(
                      'Based on your recorded app data',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: FormaColors.goldenYellow),
                    ),
                  ],
                ),
              ),
            ],
            if (isUser)
              Text(
                msg.text,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: FormaColors.charcoal,
                ),
              )
            else if (msg.isError)
              Text(
                msg.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: FormaColors.coralPink,
                ),
              )
            else
              MarkdownBody(
                data: msg.text,
                onTapLink: (text, href, title) async {
                  if (href != null) {
                    final uri = Uri.tryParse(href);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                  strong: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                  em: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                  h1: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                  h2: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                  h3: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: FormaColors.goldenYellow,
                  ),
                  listBullet: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? FormaColors.goldenYellow
                        : FormaColors.charcoal,
                  ),
                  listBulletPadding: const EdgeInsets.only(right: 8),
                  blockSpacing: 10,
                  code: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    backgroundColor: isDark
                        ? Colors.black26
                        : Colors.black.withValues(alpha: 0.05),
                    color: isDark
                        ? FormaColors.goldenYellow
                        : FormaColors.charcoal,
                  ),
                  a: const TextStyle(
                    color: FormaColors.azure,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!isUser && msg.sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                  height: 16, color: isDark ? Colors.white12 : Colors.black12),
              Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 13, color: FormaColors.goldenYellow),
                  const SizedBox(width: 4),
                  Text(
                    'Sources',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...msg.sources.map((src) => InkWell(
                    onTap: () async {
                      if (src.url.isNotEmpty) {
                        final uri = Uri.tryParse(src.url);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? FormaColors.darkSecondaryBackground
                            : FormaColors.lightSecondaryBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded,
                              size: 12, color: FormaColors.goldenYellow),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${src.name} · ${src.title}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? FormaColors.darkPrimaryText
                                    : FormaColors.lightPrimaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FormaTypingIndicator(isDark: isDark),
    );
  }

  void _sendMessage() {
    final text = _inputController.text;
    _inputController.clear();
    ref.read(personalTrainerProvider.notifier).sendMessage(text);
  }
}

/// Animated 3-dot typing bubble indicator for AI coach responses.
class FormaTypingIndicator extends StatefulWidget {
  final bool isDark;
  const FormaTypingIndicator({super.key, required this.isDark});

  @override
  State<FormaTypingIndicator> createState() => _FormaTypingIndicatorState();
}

class _FormaTypingIndicatorState extends State<FormaTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(22),
        ),
        border: Border.all(
          color: FormaColors.primaryAccent.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Personal Trainer',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: widget.isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress = (_controller.value - delay) % 1.0;
                  final bounce = progress < 0.5
                      ? (progress * 2) * (1 - (progress * 2))
                      : 0.0;

                  return Transform.translate(
                    offset: Offset(0, -bounce * 6),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: FormaColors.goldenYellow.withValues(
                          alpha: 0.35 + (bounce * 2.5).clamp(0.0, 0.65),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
