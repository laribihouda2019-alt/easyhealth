import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../models/message_model.dart';

import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import './video_call_screen.dart';
class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSendingFile = false;
  Timer? _pollTimer;

  // Attachment state
  List<int>? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages(isPoll: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool isPoll = false}) async {
    if (!isPoll) setState(() => _isLoading = true);
    try {
      final messagesData = await ApiService().getConversation(widget.recipientId);
      final newMessages = messagesData.map((msg) => MessageModel.fromJson(msg)).toList();
      
      if (!mounted) return;

      if (newMessages.length > _messages.where((m) => !m.id.startsWith('temp_')).length) {
        final bool wasAtBottom = _scrollController.hasClients && 
            _scrollController.offset >= _scrollController.position.maxScrollExtent - 50;
            
        setState(() {
          final tempMessages = _messages.where((m) => m.id.startsWith('temp_')).toList();
          
          _messages.clear();
          _messages.addAll(newMessages);
          
          for (var temp in tempMessages) {
            if (!newMessages.any((m) => m.content == temp.content && m.senderId == temp.senderId)) {
              _messages.add(temp);
            }
          }
        });

        if (wasAtBottom || !isPoll) {
          _scrollToBottom();
        }
      }
    } catch (e) {
    } finally {
      if (!isPoll && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
    }
  }

  void _clearAttachment() {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedFileBytes == null) return;

    final hasAttachment = _selectedFileBytes != null;
    final attachmentBytes = _selectedFileBytes;
    final attachmentName = _selectedFileName;

    _messageController.clear();
    _clearAttachment();

    final tempMessage = MessageModel(
      id: "temp_${DateTime.now().millisecondsSinceEpoch}",
      senderId: AuthService().currentUser?.id ?? 'me',
      recipientId: widget.recipientId,
      content: content.isNotEmpty ? content : (hasAttachment ? '📎 $attachmentName' : ''),
      sentAt: DateTime.now(),
      messageType: hasAttachment ? 'image' : 'text',
    );

    setState(() {
      _messages.add(tempMessage);
      if (hasAttachment) _isSendingFile = true;
    });

    _scrollToBottom();

    try {
      await ApiService().sendMessage(
        recipientId: widget.recipientId,
        content: content.isNotEmpty ? content : (hasAttachment ? '📎 Fichier envoyé' : ''),
        imageBytes: attachmentBytes,
        imageFileName: attachmentName,
        messageType: hasAttachment ? 'image' : 'text',
      );
      // Refresh to get the server-side image_url
      if (hasAttachment) {
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'envoi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingFile = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recipientName),
            const Text(
              'En ligne',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          if (AuthService().userRole == UserRole.doctor)
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () async {
                final currentUserId = AuthService().currentUser?.id ?? '';
                final ids = [currentUserId, widget.recipientId]..sort();
                // Combine and shorten to stay within Agora's 64-char limit
                final channelName = "call_${ids[0].substring(0, 20)}_${ids[1].substring(0, 20)}";
              
              await ApiService().sendMessage(
                recipientId: widget.recipientId,
                content: "🎥 Appel vidéo démarré",
                messageType: 'video_call',
                metadata: {'channelName': channelName},
              );

              if (mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideoCallScreen(
                      channelName: channelName,
                      remoteUserName: widget.recipientName,
                      isDoctor: true,
                      doctorId: AuthService().currentUser?.id,
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _MessageBubble(
                        message: message,
                        recipientName: widget.recipientName,
                      );
                    },
                  ),
          ),
          // Attachment preview bar
          if (_selectedFileName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.indigo.withOpacity(0.08),
              child: Row(
                children: [
                  Icon(
                    _selectedFileName!.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                    color: Colors.indigo,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFileName!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clearAttachment,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Upload progress indicator
          if (_isSendingFile)
            const LinearProgressIndicator(minHeight: 2),
          // Message input bar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickFile,
                    tooltip: 'Joindre un fichier',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ecrire un message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String recipientName;

  const _MessageBubble({
    required this.message,
    required this.recipientName,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUser?.id ?? '';
    final bool isMe = message.senderId == currentUserId;

    if (message.messageType == 'video_call') {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue.shade100 : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.videocam, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                isMe ? "Vous avez démarré un appel" : "Appel entrant",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final ids = [message.senderId, message.recipientId]..sort();
                  // Combine and shorten to stay within Agora's 64-char limit
                  final channelName = "call_${ids[0].substring(0, 20)}_${ids[1].substring(0, 20)}";
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoCallScreen(
                        channelName: channelName,
                        remoteUserName: recipientName,
                        isDoctor: AuthService().userRole == UserRole.doctor,
                        doctorId: message.senderId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.call),
                label: const Text("Rejoindre"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image attachment
            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey),
                            SizedBox(height: 4),
                            Text('Image non disponible', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Text content
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            const SizedBox(height: 4),
            Text(
              '${message.sentAt.hour}:${message.sentAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


