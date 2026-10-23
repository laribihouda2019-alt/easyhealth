import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/api_service.dart';
import '../../widgets/typing_indicator.dart';
import '../patient/doctor_list_screen.dart';

class ChatMessage {
  final String text;
  final bool isPatient;
  final String? specialty;
  final String? advice;
  final String? source;

  ChatMessage({
    required this.text,
    required this.isPatient,
    this.specialty,
    this.advice,
    this.source,
  });
}

class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({super.key});

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _api = ApiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initial greeting from the doctor
    _messages.add(ChatMessage(
      text: "Bonjour, je suis votre assistant médical virtuel. Comment puis-je vous aider aujourd'hui ? Décrivez-moi vos symptômes le plus précisément possible.",
      isPatient: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isPatient: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final data = await _api.medicalRouterRecommend(text);
      
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: data['advice'] ?? "Je vous conseille de voir un spécialiste.",
          isPatient: false,
          specialty: data['specialty'],
          advice: data['advice'],
          source: data['source'],
        ));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: "Désolé, j'ai rencontré une difficulté pour analyser vos symptômes. Veuillez réessayer.",
          isPatient: false,
        ));
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Consultation Médicale'),
            Text(
              'Assistant Virtuel Intelligent',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _DoctorBubble(isTyping: true);
                }
                final msg = _messages[index];
                return msg.isPatient
                    ? _PatientBubble(message: msg.text)
                    : _DoctorBubble(message: msg);
              },
            ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Décrivez vos symptômes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.grey[100],
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _isLoading ? null : _sendMessage,
              elevation: 0,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientBubble extends StatelessWidget {
  final String message;
  const _PatientBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withRed(100),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            child: Icon(Icons.person, color: Colors.grey[400], size: 20),
          ),
        ],
      ),
    );
  }
}

class _DoctorBubble extends StatelessWidget {
  final ChatMessage? message;
  final bool isTyping;

  const _DoctorBubble({this.message, this.isTyping = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.medical_services, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: isTyping
                      ? const TypingIndicator()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarkdownBody(
                              data: message!.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(height: 1.5, fontSize: 15, color: Colors.black87),
                                h3: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.8),
                                listBullet: const TextStyle(height: 1.5),
                              ),
                            ),
                            if (message!.source != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  message!.source!,
                                  style: TextStyle(
                                    fontSize: 10, 
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                if (!isTyping && message?.specialty != null) ...[
                  const SizedBox(height: 12),
                  _buildActionButton(context, theme, message!.specialty!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme, String specialty) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DoctorListScreen(specialty: specialty),
          ),
        );
      },
      icon: const Icon(Icons.event_available, size: 18),
      label: Text("Prendre RDV en $specialty"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}


