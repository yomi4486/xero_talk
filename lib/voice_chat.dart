import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import './utils/auth_context.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onChange);
  }

  @override
  void dispose() {
    super.dispose();
    widget.participant.removeListener(_onChange);
  }

  void _onChange() {
    var visibleVideos = widget.participant.videoTracks.where((pub) {
      return pub.kind == TrackType.VIDEO && pub.subscribed && !pub.muted;
    });

    if (visibleVideos.isNotEmpty) {
      setState(() {
        videoPub = visibleVideos.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (videoPub != null) {
      return VideoTrackRenderer(videoPub!.track as VideoTrack);
    } else {
      return Stack(
        children:[
          Container(
            margin: EdgeInsets.all(100),
            child:ClipRRect(
              borderRadius: BorderRadius.circular(100.0), 
              child: Image.network("https://${dotenv.env['BASE_URL']}/geticon?user_id=${widget.userId}"),
            )
          ),
        ]
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

  Participant<TrackPublication<Track>>? localParticipant; //自分側
  Participant<TrackPublication<Track>>? remoteParticipant; //相手側

  @override
  void initState() {
    super.initState();
    connectToLivekit();
  }

  @override
  void dispose() {
    super.dispose();
    instance.room.disconnect();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      print("Camera permission granted");
    } else {
      print("Camera permission denied");
    }

    status = await Permission.microphone.request();
    if (status.isGranted) {
      print("Microphone permission granted");
    } else {
      print("Microphone permission denied");
    }
  }

  connectToLivekit() async {
    instance.room = Room(roomOptions: roomOptions);

    instance.room.createListener().on<TrackSubscribedEvent>((event) {
      //他の参加者の接続
      print('-----track event : $event');
      setState(() {
        remoteParticipant = event.participant;
      });
    });

    try {
      await requestPermissions();
      await instance.room.connect('wss://xerotalk-zhj3ofry.livekit.cloud',widget.roomInfo.token);
    } catch (_) {
      print('Failed : $_');
    }
    await instance.room.localParticipant?.setCameraEnabled(false); //カメラの接続
    await instance.room.localParticipant?.setMicrophoneEnabled(true); //マイクの接続

    setState(() {
      localParticipant = instance.room.localParticipant;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Stack(
          children: [
            Column(
              children: [
                // local video
                localParticipant != null
                    ? Expanded(child: ParticipantWidget(localParticipant!,instance.id))
                    : Container(),
                // remote video
                remoteParticipant != null
                    ? Expanded(child: ParticipantWidget(remoteParticipant!,widget.roomInfo.userId))
                    : Container(),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.only(left: 40,right: 40,bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100.0), 
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.width * 0.15,
                      color:Colors.black,
                      child:IconButton(
                      onPressed: (){}, 
                      icon: Icon(
                        Icons.video_camera_back,
                        color: Colors.white,
                      ),
                    )
                  )),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100.0), 
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.width * 0.15,
                      color:Colors.red,
                      child:IconButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      }, 
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    )
                  )),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100.0), 
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.width * 0.15,
                      color: Colors.black,
                      child:IconButton(
                      onPressed: (){}, 
                      icon: Icon(
                        Icons.mic_off,
                        color: Colors.white,
                      ),
                    )
                  )),
                ],)
              ),
            ),
            
          ],
        )
      ),
    );
  }
}
