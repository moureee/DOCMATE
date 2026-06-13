import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      await AppData.instance.sendChatMessage(message);
      messageController.clear();
    } catch (_) {
      if (!mounted) return;
      showMessage('Message could not be sent. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  Future<void> requestCall() async {
    try {
      await AppData.instance.sendCallRequest();
      if (!mounted) return;
      showMessage('Call request sent successfully.');
    } catch (_) {
      if (!mounted) return;
      showMessage('Call request could not be sent.');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return AnimatedBuilder(
      animation: appData,
      builder: (context, child) {
        final hasPartner = appData.activeChatPartnerId.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appData.activeChatPartnerName,
                  style: const TextStyle(fontSize: 17),
                ),
                if (appData.activeChatPartnerSubtitle.isNotEmpty)
                  Text(
                    appData.activeChatPartnerSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: hasPartner ? requestCall : null,
                tooltip: 'Request a call',
                icon: const Icon(Icons.call_outlined),
              ),
            ],
          ),
          body: hasPartner
              ? Column(
                  children: [
                    Expanded(
                      child: appData.chatMessages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet. Start the conversation.',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: appData.chatMessages.length,
                              itemBuilder: (context, index) {
                                final message = appData.chatMessages[index];
                                final sentByCurrentUser =
                                    message.senderId == appData.currentUserId;

                                return Align(
                                  alignment: sentByCurrentUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 290,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: sentByCurrentUser
                                          ? AppColors.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(17),
                                        topRight: const Radius.circular(17),
                                        bottomLeft: Radius.circular(
                                          sentByCurrentUser ? 17 : 3,
                                        ),
                                        bottomRight: Radius.circular(
                                          sentByCurrentUser ? 3 : 17,
                                        ),
                                      ),
                                      border: sentByCurrentUser
                                          ? null
                                          : Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(message.message),
                                        const SizedBox(height: 5),
                                        Text(
                                          formatTime(message.time),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Write a message...',
                                  prefixIcon: Icon(Icons.chat_bubble_outline),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) {
                                  sendMessage();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.dark,
                              ),
                              onPressed: isSending ? null : sendMessage,
                              icon: isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Book or accept an appointment first. Chat becomes available between connected patients and doctors.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
        );
      },
    );
  }

  String formatTime(DateTime date) {
    var hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    return '$hour:$minute $period';
  }
}
