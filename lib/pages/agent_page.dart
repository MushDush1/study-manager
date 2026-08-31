import 'package:flutter/material.dart';

import '../services/goal_store.dart';
import '../services/study_agent.dart';
import '../theme/app_colors.dart';

void openAgentPage(BuildContext context, GoalStore store) {
    Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => AgentPage(store: store),
        ),
    );
}

class _ChatMessage {
    final String text;
    final bool fromUser;

    const _ChatMessage({
        required this.text,
        required this.fromUser,
    });
}

class AgentPage extends StatefulWidget {
    final GoalStore store;

    const AgentPage({
        super.key,
        required this.store,
    });

    @override
    State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
    final TextEditingController _controller = TextEditingController();
    final ScrollController _scrollController = ScrollController();
    late final List<_ChatMessage> _messages;

    static const _chips = ["今天学什么", "复习什么", "本周进度", "下一步建议"];

    @override
    void initState() {
        super.initState();
        _messages = [
            _ChatMessage(
                text: StudyAgent.greet(widget.store),
                fromUser: false,
            ),
        ];
    }

    @override
    void dispose() {
        _controller.dispose();
        _scrollController.dispose();
        super.dispose();
    }

    void _send(String raw) {
        final text = raw.trim();
        if (text.isEmpty) {
            return;
        }

        setState(() {
            _messages.add(_ChatMessage(text: text, fromUser: true));
            _messages.add(
                _ChatMessage(
                    text: StudyAgent.reply(widget.store, text),
                    fromUser: false,
                ),
            );
        });
        _controller.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients) {
                return;
            }
            _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
            );
        });
    }

    @override
    Widget build(BuildContext context) {
        return ColoredBox(
            color: AppColors.background,
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Scaffold(
                        backgroundColor: AppColors.background,
                        appBar: AppBar(
                            toolbarHeight: 48,
                            backgroundColor: AppColors.background,
                            foregroundColor: AppColors.text,
                            elevation: 0,
                            title: const Text("Agent"),
                            titleTextStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                            ),
                        ),
                        body: Column(
                            children: [
                                Expanded(
                                    child: ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                        itemCount: _messages.length,
                                        itemBuilder: (context, index) {
                                            return _Bubble(message: _messages[index]);
                                        },
                                    ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                    child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _chips.map((chip) {
                                            return ActionChip(
                                                label: Text(chip),
                                                onPressed: () => _send(chip),
                                            );
                                        }).toList(),
                                    ),
                                ),
                                SafeArea(
                                    top: false,
                                    child: Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                        child: Row(
                                            children: [
                                                Expanded(
                                                    child: TextField(
                                                        controller: _controller,
                                                        minLines: 1,
                                                        maxLines: 4,
                                                        textInputAction: TextInputAction.send,
                                                        onSubmitted: _send,
                                                        decoration: InputDecoration(
                                                            hintText: "问今天学什么、复习、进度…",
                                                            isDense: true,
                                                            filled: true,
                                                            fillColor: Colors.white,
                                                            contentPadding: const EdgeInsets.symmetric(
                                                                horizontal: 14,
                                                                vertical: 12,
                                                            ),
                                                            border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(16),
                                                                borderSide: const BorderSide(
                                                                    color: AppColors.border,
                                                                ),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(16),
                                                                borderSide: const BorderSide(
                                                                    color: AppColors.border,
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton.filled(
                                                    onPressed: () => _send(_controller.text),
                                                    style: IconButton.styleFrom(
                                                        backgroundColor: AppColors.primary,
                                                        foregroundColor: Colors.white,
                                                    ),
                                                    icon: const Icon(Icons.send_rounded),
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

class _Bubble extends StatelessWidget {
    final _ChatMessage message;

    const _Bubble({required this.message});

    @override
    Widget build(BuildContext context) {
        final align = message.fromUser ? Alignment.centerRight : Alignment.centerLeft;
        final color = message.fromUser ? AppColors.primary : Colors.white;
        final textColor = message.fromUser ? Colors.white : AppColors.text;

        return Align(
            alignment: align,
            child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    border: message.fromUser
                        ? null
                        : Border.all(color: AppColors.border),
                ),
                child: Text(
                    message.text,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: textColor,
                    ),
                ),
            ),
        );
    }
}
