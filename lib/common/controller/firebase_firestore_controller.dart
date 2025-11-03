import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/controller/base_controller.dart';
import 'package:bubbly/common/extensions/user_extension.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/model/livestream/app_user.dart';
import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/utilities/firebase_const.dart';

class FirebaseFirestoreController extends BaseController {
  FirebaseFirestore db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<AppUser>>? usersListener;
  RxList<AppUser> users = <AppUser>[].obs;

  static final instance = FirebaseFirestoreController();

  @override
  void onReady() {
    fetchLivestreamUsers();
    super.onReady();
  }

  void fetchLivestreamUsers() {
    close();
    usersListener = db
        .collection(FirebaseConst.appUsers)
        .withConverter<AppUser>(
            fromFirestore: (snapshot, _) {
              if (snapshot.data() != null) {
                return AppUser.fromJson(snapshot.data()!);
              } else {
                return AppUser();
              }
            },
            toFirestore: (user, _) => user.toJson())
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final user = change.doc.data();
        if (user == null) {
          Loggers.error(
              'App User data is null for doc: ${change.doc.id}, skipping...');
          continue;
        }
        final userId = user.userId;
        Loggers.info('[TYPE : ${change.type}] - ${user.toJson()}');
        switch (change.type) {
          case DocumentChangeType.added:
            users.add(user);
            break;
          case DocumentChangeType.modified:
            users.removeWhere((e) => e.userId == userId);
            users.add(user);
            break;
          case DocumentChangeType.removed:
            users.removeWhere((e) => e.userId == userId);
            break;
        }
      }
    });
  }

  void updateUser(User? user) async {
    if (user == null) return;
    DocumentSnapshot<AppUser> value = await db
        .collection(FirebaseConst.appUsers)
        .doc('${user.id}')
        .withConverter(
          fromFirestore: (snapshot, options) =>
              AppUser.fromJson(snapshot.data()!),
          toFirestore: (AppUser value, options) {
            return value.toJson();
          },
        )
        .get();
    AppUser? chatUser = user.appUser;

    if (value.exists) {
      db
          .collection(FirebaseConst.appUsers)
          .doc('${user.id}')
          .update(chatUser.toJson());
    }
  }

  void deleteUser(int? userId) async {
    if (userId == null) return;
    await db.collection(FirebaseConst.appUsers).doc('$userId').delete();

    final userListSnapshot = await db
        .collection(FirebaseConst.users)
        .doc('$userId')
        .collection(FirebaseConst.usersList)
        .get();

    final batch = db.batch();

    for (var doc in userListSnapshot.docs) {
      final otherUserId = doc.id;

      final otherUserRef = db
          .collection(FirebaseConst.users)
          .doc(otherUserId)
          .collection(FirebaseConst.usersList)
          .doc('$userId');

      final currentUserRef = db
          .collection(FirebaseConst.users)
          .doc('$userId')
          .collection(FirebaseConst.usersList)
          .doc(otherUserId);

      batch.delete(otherUserRef);
      batch.delete(currentUserRef);
    }

    await batch.commit();
  }

  void close() {
    usersListener?.cancel();
  }

  @override
  void onClose() {
    super.onClose();
    close();
  }
}
