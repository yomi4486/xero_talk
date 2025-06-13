import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import './utils/auth_context.dart';

class ParticipantWidget extends StatefulWidget {
  final Participant participant;
  final String userId;
  ParticipantWidget(this.participant, this.userId);

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
              child: UserIcon(userId: widget.userId),
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
  Set<String> _connectedParticipants = {};

  Participant? localParticipant;
  Participant? remoteParticipant;

  @override
  void initState() {
    super.initState();
    _initializeRoom();
  }

  @override
  void dispose() {
    _listener.dispose();
    instance.room.disconnect();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      cameraAvailable = true;
    }
    status = await Permission.microphone.request();
    if (status.isGranted) {
      micAvailable = true;
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
        Navigator.of(context).pop();
      })
      ..on<ParticipantConnectedEvent>((e) {
        print('Participant joined: ${e.participant.identity}');
        if (!_connectedParticipants.contains(e.participant.identity)) {
          setState(() {
            _connectedParticipants.add(e.participant.identity);
            remoteParticipant = e.participant;
          });
        }
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        print('Participant left: ${e.participant.identity}');
        setState(() {
          _connectedParticipants.remove(e.participant.identity);
          if (remoteParticipant?.identity == e.participant.identity) {
            remoteParticipant = null;
          }
        });
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
      
      await instance.room.localParticipant?.setCameraEnabled(false);
      await instance.room.localParticipant?.setMicrophoneEnabled(true);

      setState(() {
        localParticipant = instance.room.localParticipant;
      });
    } catch (e) {
      print('Failed to connect: $e');
      Navigator.of(context).pop();
    }
  }

  void _onRoomChange() {
    setState(() {
      localParticipant = instance.room.localParticipant;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Color.lerp(instance.theme[0], instance.theme[1], .5)!;
    final List<Color> textColor = instance.getTextColor(backgroundColor);
    
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
        child: Center(
          child: Stack(
            children: [
              Column(
                children: [
                  if (localParticipant != null)
                    Expanded(
                      child: ParticipantWidget(
                        localParticipant!,
                        instance.id,
                      ),
                    ),
                  if (remoteParticipant != null)
                    Expanded(
                      child: ParticipantWidget(
                        remoteParticipant!,
                        widget.roomInfo.userId,
                      ),
                    ),
                ],
              ),
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
                              onPressed: () {},
                              icon: cameraAvailable
                                  ? const Icon(
                                      Icons.video_camera_back,
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
      ),
    );
  }
}
