import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatting_app/constants.dart';

final _fireStore = FirebaseFirestore.instance;
late var loggedInUser; // don't set it to final type , as then it would not be able to log in other user from same device.

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  late String textMessage;
  late String sender;

  final messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  void dispose() {
    super.dispose();
    messageTextController.dispose();
  }

  void getCurrentUser() async {
    final user = await _auth.currentUser;
    try {
      if (user != null) {
        loggedInUser = user;
        print(user.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️ChatRoom'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            messageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      _fireStore.collection('messages').add({
                        'text': messageTextController.text,
                        'sender': loggedInUser.email,
                        // 'timestamp': FieldValue.serverTimestamp(),
                      });
                      messageTextController.clear();
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class messageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').snapshots(),
      // .orderBy('timestamp', descending: true)
      // .snapshots(),
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
            backgroundColor: Colors.lightBlueAccent,
          ));
        }
        final messages = snapshot.data.docs;
        List<MessageBubble> messageBubbleWidgets = [];
        for (var msg in messages) {
          final msgText = msg.data()['text'];
          final sender = msg.data()['sender'];
          // final msgDateTime = msg.data()['timestamp'].toDate();
          final currentUser = loggedInUser.email;

          final msgWidget = MessageBubble(
            dispMsg: msgText,
            author: sender,
            // dateTime: msgDateTime,
            isMe: currentUser == sender,
          );
          messageBubbleWidgets.add(msgWidget);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbleWidgets,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({
    required this.dispMsg,
    required this.author,
    required this.isMe,
  });

  late final String dispMsg;
  late final String author;
  // late final dateTime;
  late final bool isMe;

  @override
  Widget build(BuildContext context) {
    // final String formattedTime = DateFormat('kk:mm:a').format(dateTime);
    // final String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Text(
              ' ',
              // formattedTime + '  ' + formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Material(
              borderRadius: isMe
                  ? BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                    )
                  : BorderRadius.only(
                      topRight: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                      bottomLeft: Radius.circular(30.0),
                    ), // BoderRadius
              elevation: 5.0,
              color: isMe ? Colors.lightBlueAccent : Colors.black45,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: Text(
                  dispMsg,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ]),
    );
  }
}
