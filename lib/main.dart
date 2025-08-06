import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/screens/home_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<DiaryEntry> diaryList = [];
  final List<Friend> friendsList = [];
  
  void addDiary(DiaryEntry entry) {
    setState(() {
      diaryList.add(entry);
    });
  }
  
  void updateDiary(DiaryEntry oldEntry, DiaryEntry newEntry) {
    setState(() {
      final index = diaryList.indexOf(oldEntry);
      if (index != -1) {
        diaryList[index] = newEntry;
      }
    });
  }

  void addFriend(Friend friend) {
    setState(() {
      friendsList.add(friend);
    });
  }

  void removeFriend(Friend friend) {
    setState(() {
      friendsList.remove(friend);
    });
  }

  void updateFriend(Friend oldFriend, Friend newFriend) {
    setState(() {
      final index = friendsList.indexOf(oldFriend);
      if (index != -1) {
        friendsList[index] = newFriend;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '탈출일지',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(
        diaryList: diaryList,
        friends: friendsList,
        onAdd: addDiary,
        onUpdate: updateDiary,
        onAddFriend: addFriend,
        onRemoveFriend: removeFriend,
        onUpdateFriend: updateFriend,
      ),
    );
  }
}
