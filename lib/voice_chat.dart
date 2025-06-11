import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import './utils/auth_context.dart';

class ParticipantWidget extends StatefulWidget {
  final Participant participant;
  final String userId;
  ParticipantWidget(this.participant,this.userId);

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
    
    var visibleVideos = widget.participant.videoTracks.where((pub) {
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

  RoomInfo(
      {required this.token, required this.displayName, required this.userId});
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
  Set<String> _connectedParticipants = {};

  Participant<TrackPublication<Track>>? localParticipant;
  Participant<TrackPublication<Track>>? remoteParticipant;

  @override
  void initState() {
    super.initState();
    connectToLivekit();
  }

  @override
  void dispose() {
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

  connectToLivekit() async {
    instance.room = Room(roomOptions: roomOptions);

    instance.room.createListener()
      ..on<TrackSubscribedEvent>((event) {
        if (!_connectedParticipants.contains(event.participant.identity)) {
          setState(() {
            _connectedParticipants.add(event.participant.identity);
            remoteParticipant = event.participant;
          });
        }
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        setState(() {
          _connectedParticipants.remove(event.participant.identity);
          if (remoteParticipant?.identity == event.participant.identity) {
            remoteParticipant = null;
          }
        });
      });

    try {
      await requestPermissions();
      await instance.room.connect('wss://xerotalk-zhj3ofry.livekit.cloud', widget.roomInfo.token);
    } catch (e) {
      print('Failed to connect: $e');
    }

    await instance.room.localParticipant?.setCameraEnabled(false);
    await instance.room.localParticipant?.setMicrophoneEnabled(true);

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
                  padding: EdgeInsets.only(left: 40,right: 40,bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Material(
                      color:Colors.black.withOpacity(.5),
                      elevation: 12, // 影をより強く
                      shape: CircleBorder(),
                      child: ClipRRect( // camera
                        borderRadius: BorderRadius.circular(100.0), 
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: MediaQuery.of(context).size.width * 0.15,
                          color:textColor[0].withOpacity(.5),
                          child:IconButton(
                          onPressed: (){}, 
                          icon: cameraAvailable ? Icon(
                            Icons.video_camera_back,
                            color: Colors.white,
                          )
                          :
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.video_camera_back,color: Colors.white), // メインアイコン
                              Icon(Icons.block,color: Colors.white,size:MediaQuery.of(context).size.width * 0.1), // オーバーレイアイコン
                            ],
                          ),
                          )
                        )
                      ),
                    ),
                    Material(
                      elevation: 12, // 影をより強く
                      shape: CircleBorder(),
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
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color:Colors.black.withOpacity(.5),
                      elevation: 12, // 影をより強く
                      shape: CircleBorder(),
                      child: ClipRRect( // mute button
                        borderRadius: BorderRadius.circular(100.0), 
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: MediaQuery.of(context).size.width * 0.15,
                          color: textColor[0].withOpacity(.8),
                          child:IconButton(
                          onPressed: ()async{
                            if(!micAvailable){
                              return;
                            }
                            if(instance.room.localParticipant!.isMuted){
                              await instance.room.localParticipant?.setMicrophoneEnabled(true);
                            }else{
                              await instance.room.localParticipant?.setMicrophoneEnabled(false);
                            }
                            setState(() {});
                          }, 
                          icon: micAvailable? 
                          Icon(
                            instance.room.localParticipant?.isMuted != null && instance.room.localParticipant!.isMuted ? Icons.mic_off:Icons.mic,
                            color: Colors.white,
                          )
                          :
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.mic,color: Colors.white), // メインアイコン
                              Icon(Icons.block,color: Colors.white,size:MediaQuery.of(context).size.width * 0.1), // オーバーレイアイコン
                            ],
                          ),
                        )
                      )
                    )
                    ),
                  ],)
                ),
              ),
            ],
          )
        ),
      ));
  }
}
