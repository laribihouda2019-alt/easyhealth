import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'chat_screen.dart';
import '../patient/professional_discovery_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _api = ApiService();
  final _auth = AuthService();
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversationsRaw = await _api.getMyConversations();
      final conversations = conversationsRaw.map((e) => Map<String, dynamic>.from(e)).toList();

      for (var i = 0; i < conversations.length; i++) {
        var conv = conversations[i];
        try {
          final profile = await _api.getUserProfile(conv['id']);
          if (profile['full_name'] != null && profile['full_name'].toString().isNotEmpty) conv['full_name'] = profile['full_name'];
          if (profile['displayName'] != null && profile['displayName'].toString().isNotEmpty) conv['full_name'] = profile['displayName'];
          if (profile['name'] != null && profile['name'].toString().isNotEmpty) conv['full_name'] = profile['name'];
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des messages: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messagerie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune conversation pour le moment',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    final otherUserId = conv['id'] as String;
                    final otherUserName = conv['full_name'] as String? ?? 'Utilisateur';
                    final lastMessageContent = conv['last_message'] as String? ?? 'Pas de message';
                    final lastMessageTime = conv['last_message_time'] as String?;
                    
                    // Filter logic: In a real system the backend should handle this, 
                    // but we can add UI hints here if needed.
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(
                          (otherUserName).isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        otherUserName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lastMessageContent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: lastMessageTime != null
                          ? Text(
                              _formatTime(lastMessageTime),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            )
                          : null,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              recipientId: otherUserId,
                              recipientName: otherUserName,
                            ),
                          ),
                        );
                        _fetchConversations(); // Refresh when coming back
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfessionalDiscoveryScreen()),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}


