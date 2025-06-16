import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import './utils/auth_context.dart';
import 'package:camera/camera.dart';

class ParticipantWidget extends StatefulWidget {
  final Participant participant;
  ParticipantWidget(this.participant);

  @override
  State<StatefulWidget> createState() {
    return _ParticipantState();
  }
}

class _ParticipantState extends State<ParticipantWidget> {
  TrackPublication? videoPub;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onChange);
    _updateVideoTrack();
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.participant.removeListener(_onChange);
    super.dispose();
  }

  void _updateVideoTrack() {
    if (_isDisposed) return;
    
    var visibleVideos = widget.participant.videoTrackPublications.where((pub) {
      return pub.kind == TrackType.VIDEO && pub.subscribed && !pub.muted;
    });

    if (visibleVideos.isNotEmpty) {
      setState(() {
        videoPub = visibleVideos.first;
      });
    } else {
      setState(() {
        videoPub = null;
      });
    }
  }

  void _onChange() {
    if (!_isDisposed) {
      _updateVideoTrack();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (videoPub != null) {
      return VideoTrackRenderer(videoPub!.track as VideoTrack);
    } else {
      return Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(100),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100.0),
              child: UserIcon(userId: widget.participant.identity),
            ),
          ),
        ],
      );
    }
  }
}

class RoomInfo {
  String token;
  String displayName;
  String userId;

  RoomInfo({
    required this.token,
    required this.displayName,
    required this.userId,
  });
}

class VoiceChat extends StatefulWidget {
  final RoomInfo roomInfo;

  VoiceChat(this.roomInfo);

  @override
  State<StatefulWidget> createState() {
    return _VoiceChatState();
  }
}

class _VoiceChatState extends State<VoiceChat> {
  final instance = AuthContext();
  final roomOptions = const RoomOptions(
    adaptiveStream: true,
    dynacast: true,
  );

  bool micAvailable = false;
  bool cameraAvailable = false;
  late final EventsListener<RoomEvent> _listener;
  bool _isFrontCamera = true;

  Participant? localParticipant;
  List<Participant> remoteParticipants = [];
  Participant? _selectedParticipant; // 選択された参加者

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _listener.dispose();
    instance.room.disconnect();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // カメラの使用可否を確認
    var cameraStatus = await Permission.camera.status;
    bool hasCameraPermission = cameraStatus.isGranted;
    
    // カメラデバイスの存在確認
    bool hasCameraDevice = false;
    try {
      final cameras = await availableCameras();
      hasCameraDevice = cameras.isNotEmpty;
    } catch (e) {
      print('Error checking camera devices: $e');
      hasCameraDevice = false;
    }

    // カメラの使用可否は権限とデバイスの両方が必要
    cameraAvailable = hasCameraPermission && hasCameraDevice;
    if (!cameraAvailable) {
      print('Camera not available: Permission: $hasCameraPermission, Device: $hasCameraDevice');
    }

    // マイクの使用可否を確認
    var micStatus = await Permission.microphone.status;
    if (micStatus.isGranted) {
      micAvailable = true;
    } else {
      micAvailable = false;
      print('Microphone permission not granted');
    }

    // 権限の確認が完了したらルームを初期化
    _initializeRoom();
  }

  Future<void> requestPermissions() async {
    if (!cameraAvailable) {
      var status = await Permission.camera.request();
      if (status.isGranted) {
        cameraAvailable = true;
      }
    }
    
    if (!micAvailable) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        micAvailable = true;
      }
    }
  }

  Future<void> _switchCamera() async {
    if (instance.room.localParticipant != null) {
      // カメラを切り替えて有効化
     setState(() {_isFrontCamera = !_isFrontCamera;});
    }
  }

  void _initializeRoom() async {
    instance.room = Room(roomOptions: roomOptions);
    _listener = instance.room.createListener();

    // ルームの状態変更を監視
    instance.room.addListener(_onRoomChange);

    // 特定のイベントを監視
    _listener
      ..on<RoomDisconnectedEvent>((_) {
        print('Room disconnected');
      })
      ..on<ParticipantConnectedEvent>((e) {
        print('Participant joined: ${e.participant.identity}');
        _updateParticipants();
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        print('Participant left: ${e.participant.identity}');
        _updateParticipants();
      })
      ..on<TrackSubscribedEvent>((e) {
        print('Track subscribed: ${e.track.kind}');
        setState(() {});
      })
      ..on<TrackUnsubscribedEvent>((e) {
        print('Track unsubscribed: ${e.track.kind}');
        setState(() {});
      });

    try {
      await requestPermissions();
      await instance.room.connect('wss://xerotalk-zhj3ofry.livekit.cloud', widget.roomInfo.token);
      
      // カメラが使用可能な場合のみカメラを有効化
      if (cameraAvailable) {
        await instance.room.localParticipant?.setCameraEnabled(false,cameraCaptureOptions: CameraCaptureOptions(cameraPosition: _isFrontCamera ? CameraPosition.front : CameraPosition.back));
      }
      await instance.room.localParticipant?.setMicrophoneEnabled(true);

      setState(() {   
        localParticipant = instance.room.localParticipant;
      });
    } catch (e) {
      print('Failed to connect: $e');
      Navigator.of(context).pop();
    }
  }

  void _updateParticipants() {
    setState(() {
      remoteParticipants = instance.room.remoteParticipants.values.toList();
    });
  }

  void _onRoomChange() {
    setState(() {
      localParticipant = instance.room.localParticipant;
      remoteParticipants = instance.room.remoteParticipants.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Color.lerp(instance.theme[0], instance.theme[1], .5)!;
    final List<Color> textColor = instance.getTextColor(backgroundColor);
    final size = MediaQuery.of(context).size;
    
    // 参加者リストを作成（ローカル参加者を含む）
    final allParticipants = [
      if (localParticipant != null) localParticipant!,
      ...remoteParticipants,
    ];

    // グリッドのレイアウトを計算
    int crossAxisCount = allParticipants.length <= 1 ? 1 : 
                        allParticipants.length <= 2 ? 1 : 
                        allParticipants.length <= 4 ? 2 : 3;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset.topLeft,
            end: FractionalOffset.bottomRight,
            colors: instance.theme,
            stops: const [0.0, 1.0],
          ),
        ),
        child:SafeArea(child: Stack(
          children: [
            // メイン表示（選択された参加者または通常のグリッド）
            if (_selectedParticipant != null)
              // 選択された参加者の拡大表示
              Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedParticipant = null;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedParticipant == localParticipant ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              ParticipantWidget(
                                _selectedParticipant!,
                              ),
                              if (_selectedParticipant == localParticipant)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'あなた',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 他の参加者の小さな表示
                  SizedBox(
                    height: size.height * 0.2,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allParticipants.length - 1,
                      itemBuilder: (context, index) {
                        final participant = allParticipants.firstWhere(
                          (p) => p != _selectedParticipant
                        );
                        final isLocal = participant == localParticipant;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedParticipant = participant;
                            });
                          },
                          child: Container(
                            width: size.width * 0.3,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLocal ? Colors.blue : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                children: [
                                  ParticipantWidget(
                                    participant,
                                  ),
                                  if (isLocal)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'あなた',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            else
              // 通常のグリッド表示
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: allParticipants.length,
                  itemBuilder: (context, index) {
                    final participant = allParticipants[index];
                    final isLocal = participant == localParticipant;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedParticipant = participant;
                        });
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: size.height * 0.4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLocal ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              ParticipantWidget(
                                participant,
                              ),
                              if (isLocal)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'あなた',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // コントロールバー
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(left: 40, right: 40, bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.black.withOpacity(.5),
                      elevation: 12,
                      shape: const CircleBorder(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: MediaQuery.of(context).size.width * 0.15,
                          color: textColor[0].withOpacity(.5),
                          child: IconButton(
                            onPressed: cameraAvailable ? () async {
                              if (instance.room.localParticipant?.isCameraEnabled() ?? false) {
                                await instance.room.localParticipant?.setCameraEnabled(false,cameraCaptureOptions: CameraCaptureOptions(cameraPosition: _isFrontCamera ? CameraPosition.front : CameraPosition.back));
                              } else {
                                await instance.room.localParticipant?.setCameraEnabled(true,cameraCaptureOptions: CameraCaptureOptions(cameraPosition: _isFrontCamera ? CameraPosition.front : CameraPosition.back));
                              }
                              setState(() {});
                            } : null,
                            icon: cameraAvailable
                                ? Icon(
                                    instance.room.localParticipant?.isCameraEnabled() ?? false
                                        ? Icons.video_camera_back
                                        : Icons.videocam_off,
                                    color: Colors.white,
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(Icons.video_camera_back,
                                          color: Colors.white),
                                      Icon(
                                          Icons.block,
                                          color: Colors.white,
                                          size: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    // カメラ切り替えボタンを追加
                    if (cameraAvailable && (instance.room.localParticipant?.isCameraEnabled() ?? false))
                      Material(
                        color: Colors.black.withOpacity(.5),
                        elevation: 12,
                        shape: const CircleBorder(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.15,
                            color: textColor[0].withOpacity(.5),
                            child: IconButton(
                              onPressed: () async {
                                await _switchCamera();
                              },
                              icon: Icon(
                                Icons.cameraswitch,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Material(
                      elevation: 12,
                      shape: const CircleBorder(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: MediaQuery.of(context).size.width * 0.15,
                          color: Colors.red.withOpacity(.8),
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.black.withOpacity(.5),
                      elevation: 12,
                      shape: const CircleBorder(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: MediaQuery.of(context).size.width * 0.15,
                          color: textColor[0].withOpacity(.8),
                          child: IconButton(
                            onPressed: () async {
                              if (!micAvailable) return;
                              if (instance.room.localParticipant!.isMuted) {
                                await instance.room.localParticipant
                                    ?.setMicrophoneEnabled(true);
                              } else {
                                await instance.room.localParticipant
                                    ?.setMicrophoneEnabled(false);
                              }
                              setState(() {});
                            },
                            icon: micAvailable
                                ? Icon(
                                    instance.room.localParticipant?.isMuted !=
                                                null &&
                                            instance.room.localParticipant!
                                                .isMuted
                                        ? Icons.mic_off
                                        : Icons.mic,
                                    color: Colors.white,
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(Icons.mic,
                                          color: Colors.white),
                                      Icon(
                                          Icons.block,
                                          color: Colors.white,
                                          size: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
    );
  }
}
