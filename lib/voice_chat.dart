import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

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
      return Container(
        color: Colors.grey,
      );
    }
  }
}

class RoomInfo {
  String token;
  String displayName;
  String iconUrl;

  RoomInfo({required this.token, required this.displayName, required this.iconUrl});
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
  final roomOptions = const RoomOptions(
    adaptiveStream: true,
    dynacast: true,
  );

  Participant<TrackPublication<Track>>? localParticipant; //自分側
  Participant<TrackPublication<Track>>? remoteParticipant; //相手側
  Room? roomstate;

  @override
  void initState() {
    super.initState();
    connectToLivekit();
  }

  connectToLivekit() async {
    const String url = 'wss://xerotalk-zhj3ofry.livekit.cloud';
    final String token = widget.roomInfo.token;
    final room = Room(roomOptions: roomOptions);
    roomstate = room;

    room.createListener().on<TrackSubscribedEvent>((event) {
      //他の参加者の接続
      print('-----track event : $event');
      setState(() {
        remoteParticipant = event.participant;
      });
    });

    try {
      await room.connect(url,token);
    } catch (_) {
      print('Failed : $_');
    }

    setState(() {
      localParticipant = room.localParticipant!;
    });

    await room.localParticipant!.setCameraEnabled(true); //カメラの接続
    await room.localParticipant!.setMicrophoneEnabled(true); //マイクの接続
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            // local video
            localParticipant != null
                ? Expanded(child: ParticipantWidget(localParticipant!))
                : const CircularProgressIndicator(),
            // remote video
            remoteParticipant != null
                ? Expanded(child: ParticipantWidget(remoteParticipant!))
                : const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

