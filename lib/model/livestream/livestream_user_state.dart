import 'package:get/get.dart';
import 'package:bubbly/model/livestream/app_user.dart';

class LivestreamUserState {
  bool isMuted;
  bool isVideoOn;
  LivestreamUserType type;
  int userId;
  int liveCoin;
  int currentBattleCoin;
  int totalBattleCoin;
  List<int> followersGained;
  int joinStreamTime;
  AppUser? user;

  LivestreamUserState(
      {required this.isMuted,
      required this.isVideoOn,
      required this.type,
      required this.userId,
      required this.liveCoin,
      required this.currentBattleCoin,
      required this.totalBattleCoin,
      required this.followersGained,
      required this.joinStreamTime,
      this.user});

  factory LivestreamUserState.fromJson(Map<String, dynamic> json) {
    return LivestreamUserState(
        isMuted: json['is_muted'] ?? false,
        isVideoOn: json['is_video_on'] ?? true,
        type: LivestreamUserType.fromString(json['type'] ?? ''),
        userId: json['user_id'] ?? 0,
        liveCoin: json['live_coin'] ?? 0,
        currentBattleCoin: json['current_battle_coin'] ?? 0,
        totalBattleCoin: json['total_battle_coin'] ?? 0,
        followersGained: json['followers_gained'].cast<int>() ?? [],
        joinStreamTime: json['join_stream_time'] ?? 0,
        user: json['user'] != null ? AppUser.fromJson(json['user']) : null);
  }

  Map<String, dynamic> toJson() {
    return {
      'is_muted': isMuted,
      'is_video_on': isVideoOn,
      'type': type.value,
      'user_id': userId,
      'live_coin': liveCoin,
      'current_battle_coin': currentBattleCoin,
      'total_battle_coin': totalBattleCoin,
      'followers_gained': followersGained,
      'join_stream_time': joinStreamTime,
      if (user != null) 'user': user?.toJson()
    };
  }

  AppUser? getUser(List<AppUser> users) {
    return users.firstWhereOrNull((element) => element.userId == userId);
  }

  int get totalCoin {
    return totalBattleCoin + liveCoin;
  }
}

enum LivestreamUserType {
  host('HOST'),
  coHost('CO-HOST'),
  audience('AUDIENCE'),
  requested('REQUESTED'),
  invited('INVITED'),
  left('LEFT');

  final String value;

  const LivestreamUserType(this.value);

  static LivestreamUserType fromString(String value) {
    return LivestreamUserType.values.firstWhereOrNull(
          (e) => e.value == value,
        ) ??
        LivestreamUserType.audience;
  }
}