import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import '../../controllers/video_call_controller.dart';
import '../../services/api_service.dart';
import '../patient/payment_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String remoteUserName;
  final bool isDoctor;
  final String? doctorId;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.remoteUserName,
    this.isDoctor = false,
    this.doctorId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late VideoCallController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoCallController();
    _controller.initAgoraAndJoinChannel(widget.channelName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoCallController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<VideoCallController>(
          builder: (context, controller, _) {
            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            if (!controller.isEngineInitialized || !controller.isJoined) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            return Stack(
              children: [
                // 1. Full Screen Remote View
                Positioned.fill(
                  child: _buildRemoteView(controller),
                ),
                
                // 2. Translucent User Overlay (Top)
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              widget.remoteUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Duration or Status could go here
                    ],
                  ),
                ),

                // 3. Floating Picture-in-Picture (PiP) for Local Preview
                Positioned(
                  top: 100,
                  right: 20,
                  child: _buildLocalView(controller),
                ),
                
                // 4. Floating Action Controls (Bottom)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionBar(controller),
                      const SizedBox(height: 20),
                      // Prominent End Call Button
                      FloatingActionButton(
                        backgroundColor: Colors.red,
                        onPressed: () {
                          if (!widget.isDoctor && widget.doctorId != null) {
                            Navigator.of(context).pop(); // Close video call
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PaymentProxyScreen(
                                  doctorId: widget.doctorId!,
                                  doctorName: widget.remoteUserName,
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Icon(Icons.call_end, size: 30, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRemoteView(VideoCallController controller) {
    if (controller.remoteUids.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  widget.isDoctor
                      ? "En attente de ${widget.remoteUserName}..."
                      : "En attente du médecin pour commencer la consultation...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!widget.isDoctor) ...[
                const SizedBox(height: 16),
                const Text(
                  "Veuillez patienter, le médecin rejoindra l'appel sous peu.",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final remoteUid = controller.remoteUids.first;

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: controller.engine,
        canvas: VideoCanvas(
          uid: remoteUid,
          renderMode: RenderModeType.renderModeHidden, // Fills the container
        ),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  Widget _buildLocalView(VideoCallController controller) {
    return Container(
      width: 110,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: controller.isVideoDisabled
            ? const Center(child: Icon(Icons.videocam_off, color: Colors.white54))
            : AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: controller.engine,
                  canvas: const VideoCanvas(
                    uid: 0,
                    renderMode: RenderModeType.renderModeHidden,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionBar(VideoCallController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            icon: controller.isMuted ? Icons.mic_off : Icons.mic,
            isActive: !controller.isMuted,
            onPressed: () => controller.toggleMute(),
          ),
          _controlButton(
            icon: controller.isVideoDisabled ? Icons.videocam_off : Icons.videocam,
            isActive: !controller.isVideoDisabled,
            onPressed: () => controller.toggleVideo(),
          ),
          _controlButton(
            icon: Icons.switch_camera,
            isActive: true,
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: isActive ? Colors.white.withOpacity(0.2) : Colors.red.withOpacity(0.8),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }
}

class PaymentProxyScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const PaymentProxyScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<PaymentProxyScreen> createState() => _PaymentProxyScreenState();
}

class _PaymentProxyScreenState extends State<PaymentProxyScreen> {
  bool _isLoading = true;
  double? _consultationFee;

  @override
  void initState() {
    super.initState();
    _fetchDoctorFee();
  }

  Future<void> _fetchDoctorFee() async {
    try {
      final profileData = await ApiService().getUserProfile(widget.doctorId);
      final fee = profileData['consultation_fee'];
      setState(() {
        if (fee is num) {
          _consultationFee = fee.toDouble();
        } else if (fee is String) {
          _consultationFee = double.tryParse(fee);
        }
        // Default to 2500 if not set
        _consultationFee ??= 2500.0;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _consultationFee = 2500.0; // fallback
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // We navigate directly to PaymentScreen bypassing this wrapper by using Replacement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              appointment: null, // We will refactor PaymentScreen to accept optional args
              amount: _consultationFee!,
              doctorName: widget.doctorName,
            ),
          ),
        );
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


