import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile otherUser;

  const ChatScreen({
    Key? key,
    required this.otherUser,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _deliveryRequested = false;
  String? _deliveryAddress;
  bool _showDeliveryOptions = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkIfCanRequestDelivery();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getConversation(widget.otherUser.id);
      
      if (response.statusCode == 200) {
        final messagesData = response.data['data'] as List;
        setState(() {
          _messages = messagesData
              .map((msg) => Message.fromJson(msg))
              .toList();
        });
        
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      _showErrorSnackBar('Erreur lors du chargement des messages');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkIfCanRequestDelivery() {
    // Seuls les patients peuvent demander la livraison aux pharmacies
    setState(() {
      _showDeliveryOptions = _isPatientToPharmacyConversation();
    });
  }

  bool _isPatientToPharmacyConversation() {
    // Logique simplifiée - dans une vraie app, vous vérifieriez le rôle de l'utilisateur actuel
    return widget.otherUser.role == 'pharmacy';
  }

  Future<void> _sendMessage({String? imagePath}) async {
    if (_messageController.text.trim().isEmpty && imagePath == null) return;

    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_user_id', // À remplacer avec l'ID réel
      recipientId: widget.otherUser.id,
      content: _messageController.text.trim(),
      sentAt: DateTime.now(),
      deliveryRequested: _deliveryRequested,
      deliveryAddress: _deliveryAddress,
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    _messageController.clear();

    try {
      final response = await ApiService.sendMessage(
        recipientId: widget.otherUser.id,
        content: tempMessage.content,
        imagePath: imagePath,
        deliveryRequested: _deliveryRequested,
        deliveryAddress: _deliveryAddress,
      );

      if (response.statusCode == 201) {
        // Recharger les messages pour obtenir l'état correct
        await _loadMessages();
      }
    } catch (e) {
      print('Send message error: $e');
      _showErrorSnackBar('Erreur lors de l\'envoi du message');
      
      // Retirer le message temporaire en cas d'erreur
      setState(() {
        _messages.remove(tempMessage);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _sendMessage(imagePath: image.path);
      }
    } catch (e) {
      print('Pick image error: $e');
      _showErrorSnackBar('Erreur lors de la sélection de l\'image');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (photo != null) {
        await _sendMessage(imagePath: photo.path);
      }
    } catch (e) {
      print('Take photo error: $e');
      _showErrorSnackBar('Erreur lors de la prise de photo');
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisir une image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.blue),
              SizedBox(width: 8),
              Text('Demande de Livraison'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Faites livrer vos médicaments à domicile',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Demander la livraison'),
                subtitle: Text('Frais de livraison applicables'),
                value: _deliveryRequested,
                onChanged: (value) {
                  setDialogState(() => _deliveryRequested = value!);
                },
              ),
              if (_deliveryRequested) ...[
                SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Adresse de livraison',
                    hintText: 'Rue, Ville, Code postal...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    setDialogState(() => _deliveryAddress = value);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
                _showSuccessSnackBar('Options de livraison mises à jour');
              },
              child: Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                _getRoleIcon(widget.otherUser.role),
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName,
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.otherUser.roleDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_showDeliveryOptions)
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.delivery_dining),
                  if (_deliveryRequested)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
              ],
            ),
              onPressed: _showDeliveryDialog,
              tooltip: 'Options de livraison',
            ),
        ],
      ),
      body: Column(
        children: [
          // Delivery status indicator
          if (_deliveryRequested && _deliveryAddress != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Livraison demandée',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        Text(
                          _deliveryAddress!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun message',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Envoyez votre premier message',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId != widget.otherUser.id;
                          
                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            showDeliveryInfo: _showDeliveryOptions,
                          );
                        },
                      ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.photo, color: Colors.blue.shade600),
            onPressed: _showImagePicker,
            tooltip: 'Envoyer une image',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(),
              tooltip: 'Envoyer',
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'patient':
        return Icons.person;
      case 'doctor':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'lab':
        return Icons.science;
      default:
        return Icons.person;
    }
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showDeliveryInfo;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showDeliveryInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue.shade600 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                      bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.hasImage) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.imageUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.shade300,
                                child: Icon(Icons.image, color: Colors.grey.shade600),
                              );
                            },
                          ),
                        ),
                        if (message.content.isNotEmpty) SizedBox(height: 8),
                      ],
                      if (message.content.isNotEmpty)
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Delivery info
                if (showDeliveryInfo && message.hasDelivery)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delivery_dining, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Livraison: ${message.deliveryStatusDisplay}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 2),
                Text(
                  message.timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) SizedBox(width: 8),
        ],
      ),
    );
  }
}
