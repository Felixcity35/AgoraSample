import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(home: LivestreamPage()));
}

class LivestreamPage extends StatefulWidget {
  const LivestreamPage({super.key});

  @override
  State<LivestreamPage> createState() => _LivestreamPageState();
}

class _LivestreamPageState extends State<LivestreamPage> {
  static const String appId = '517550b42d8a4bbda1cc7e5479d78f29';
  static const String token =
      '007eJxTYJggd63BUjZqR46xa+6ze6y/LN2m6W0Xj7g3ze0hn3z017MKDKaG5qamBkkmRikWiSZJSSmJhsnJ5qmmJuaWKeYWaUaWr6r/pTcEMjIose1nZGSAQBCfk6EktbgkPiezLJWBAQCvDCEK';
  static const String channelName = 'test_live';

  late RtcEngine _engine;
  bool isJoined = false;
  bool isHost = true;
  int? remoteUid;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    await _engine.enableVideo();
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(
      role: isHost
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => isJoined = true);
          print('Joined channel');
        },
        onUserJoined: (connection, uid, elapsed) {
          setState(() => remoteUid = uid);
          print('Remote user joined: $uid');
        },
        onUserOffline: (connection, uid, reason) {
          setState(() => remoteUid = null);
          print('Remote user left: $uid');
        },
      ),
    );
  }

  Future<void> _join() async {
    await _engine.setClientRole(
      role: isHost
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );

    if (isHost) {
      await _engine.startPreview();
    }
  }

  Future<void> _leave() async {
    await _engine.leaveChannel();
    setState(() {
      isJoined = false;
      remoteUid = null;
    });
  }

  @override
  void dispose() {
    _engine.release();
    super.dispose();
  }

  Widget _renderVideo() {
    if (isHost) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      if (remoteUid != null) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: remoteUid),
            connection: const RtcConnection(channelId: channelName),
          ),
        );
      } else {
        return const Center(child: Text("Waiting for host..."));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agora Livestream")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: isJoined
                  ? _renderVideo()
                  : const Center(child: Text("Not connected")),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text("Join as: "),
                    Switch(
                      value: isHost,
                      onChanged: (val) {
                        setState(() => isHost = val);
                      },
                    ),
                    Text(isHost ? "Host" : "Audience"),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isJoined ? _leave : _join,
                  child: Text(isJoined ? "Leave Channel" : "Join Channel"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
