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
  bool choosingPartner = true;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty || isSending) return;

    setState(() => isSending = true);

    try {
      await AppData.instance.sendChatMessage(message);
      messageController.clear();
    } catch (_) {
      if (!mounted) return;
      showMessage('Message could not be sent. Please try again.');
    } finally {
      if (mounted) setState(() => isSending = false);
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

  void selectPartner(ChatPartnerModel partner) {
    AppData.instance.selectChatPartner(partner);
    setState(() => choosingPartner = false);
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return AnimatedBuilder(
      animation: appData,
      builder: (context, child) {
        final partners = appData.chatPartners;
        final hasPartner = appData.activeChatPartnerId.isNotEmpty;
        final partnerLabel = appData.currentUserRole == 'doctor'
            ? 'Select a patient'
            : 'Select a doctor';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              choosingPartner || !hasPartner
                  ? 'Chat'
                  : appData.activeChatPartnerName,
            ),
            actions: [
              if (!choosingPartner && hasPartner)
                IconButton(
                  tooltip: 'Change chat contact',
                  onPressed: () => setState(() => choosingPartner = true),
                  icon: const Icon(Icons.people_outline),
                ),
              IconButton(
                onPressed: !choosingPartner && hasPartner ? requestCall : null,
                tooltip: 'Request a call',
                icon: const Icon(Icons.call_outlined),
              ),
            ],
          ),
          body: partners.isEmpty
              ? buildNoPartnerState(appData)
              : choosingPartner || !hasPartner
                  ? buildPartnerPicker(partnerLabel, partners)
                  : buildConversation(appData),
        );
      },
    );
  }

  Widget buildNoPartnerState(AppData appData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 54,
              color: AppColors.primaryDark,
            ),
            const SizedBox(height: 14),
            Text(
              appData.currentUserRole == 'doctor'
                  ? 'No patient chats yet.'
                  : 'No doctor chats yet.',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appData.currentUserRole == 'doctor'
                  ? 'Patient chats appear after appointments are booked with you.'
                  : 'Book an appointment first, then select the doctor you want to chat with.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPartnerPicker(
    String partnerLabel,
    List<ChatPartnerModel> partners,
  ) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          partnerLabel,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose who you want to talk to. DocMate will open that conversation only.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        ...partners.map((partner) {
          final selected = partner.id == AppData.instance.activeChatPartnerId;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primaryDark : Colors.grey.shade300,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.lightMint,
                child: Icon(
                  AppData.instance.currentUserRole == 'doctor'
                      ? Icons.person_outline
                      : Icons.medical_services_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
              title: Text(
                partner.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(partner.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => selectPartner(partner),
            ),
          );
        }),
      ],
    );
  }

  Widget buildConversation(AppData appData) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: AppColors.lightMint,
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appData.activeChatPartnerSubtitle.isEmpty
                      ? appData.activeChatPartnerName
                      : '${appData.activeChatPartnerName} • ${appData.activeChatPartnerSubtitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => choosingPartner = true),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change'),
              ),
            ],
          ),
        ),
        Expanded(
          child: appData.chatMessages.isEmpty
              ? const Center(
                  child: Text('No messages yet. Start the conversation.'),
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
                        constraints: const BoxConstraints(maxWidth: 290),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: sentByCurrentUser
                              ? AppColors.primary
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(17),
                            topRight: const Radius.circular(17),
                            bottomLeft:
                                Radius.circular(sentByCurrentUser ? 17 : 3),
                            bottomRight:
                                Radius.circular(sentByCurrentUser ? 3 : 17),
                          ),
                          border: sentByCurrentUser
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
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
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
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
                    onSubmitted: (_) => sendMessage(),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
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
