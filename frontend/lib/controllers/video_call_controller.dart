import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class VideoCallController extends ChangeNotifier {
  late RtcEngine _engine;
  bool _isEngineInitialized = false;
  bool _isJoined = false;
  
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  
  int? _localUid;
  final Set<int> _remoteUids = {};
  
  String? _errorMessage;

  // Getters for UI
  bool get isEngineInitialized => _isEngineInitialized;
  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isVideoDisabled => _isVideoDisabled;
  int? get localUid => _localUid;
  Set<int> get remoteUids => _remoteUids;
  String? get errorMessage => _errorMessage;

  /// Starts the initialization process
  Future<void> initAgoraAndJoinChannel(String channelName) async {
    try {
      _errorMessage = null;
      notifyListeners();

      // 1. Check permissions (Not required for Web, but good for mobile)
      if (!kIsWeb) {
        await [Permission.camera, Permission.microphone].request();
      }

      // 2. Fetch the dynamically generated token from backend
      final tokenData = await ApiService().getAgoraToken(channelName);
      if (!tokenData.containsKey('token') || !tokenData.containsKey('appID')) {
        throw Exception("Failed to get token or appID from server.");
      }

      final String token = tokenData['token'];
      final String appId = tokenData['appID'];
      // The backend assigns a UID (or we pass 0 for dynamic)
      final int uid = tokenData['uid'] ?? 0;

      // 3. Create and initialize RtcEngine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _isEngineInitialized = true;

      // 4. Setup Event Handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _isJoined = true;
            _localUid = connection.localUid;
            notifyListeners();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            _remoteUids.add(remoteUid);
            notifyListeners();
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _remoteUids.remove(remoteUid);
            notifyListeners();
          },
          onError: (ErrorCodeType err, String msg) {
            if (err == ErrorCodeType.errInvalidToken || err == ErrorCodeType.errTokenExpired) {
               _errorMessage = "Token expiré ou invalide.";
               notifyListeners();
            }
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            // Auto-refresh token could be implemented here
          },
        ),
      );

      // 5. Enable Video
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.enableVideo();
      await _engine.startPreview();

      // 6. Join Channel
      await _engine.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
        ),
      );

    } catch (e) {
      _errorMessage = "Erreur lors de l'initialisation de l'appel. $e";
      notifyListeners();
    }
  }

  RtcEngine get engine => _engine;

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _engine.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    _isVideoDisabled = !_isVideoDisabled;
    await _engine.muteLocalVideoStream(_isVideoDisabled);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    try {
      await _engine.switchCamera();
    } catch (e) {
    }
  }

  Future<void> endCall() async {
    try {
      if (_isEngineInitialized) {
        await _engine.leaveChannel();
        await _engine.release();
        _isEngineInitialized = false;
        _isJoined = false;
        _remoteUids.clear();
      }
    } catch (e) {
    }
    notifyListeners();
  }

  @override
  void dispose() {
    endCall();
    super.dispose();
  }
}


