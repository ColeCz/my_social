// this is configured to run on the web since it better for my pc health,
// but it is also configured to run on an emulator.

import 'LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyBil5zJQrctGC-5Lqh2aGKh4APC6WOLwuw",
        authDomain: "my-social-cfc60.firebaseapp.com",
        projectId: "my-social-cfc60",
        storageBucket: "my-social-cfc60.appspot.com",
        messagingSenderId: "141716642377",
        appId: "1:141716642377:web:6888caac9e361832767d98"
    ),
  );
  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: LoginPage(),
    );
  }
}

class FireStoreApp extends StatefulWidget {
  final User? user;

  FireStoreApp({required this.user});

  @override
  _FireStoreAppState createState() => _FireStoreAppState();
}

class _FireStoreAppState extends State<FireStoreApp> {
  final CollectionReference pictures =
  FirebaseFirestore.instance.collection('pictures');
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Social App'),
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${widget.user?.email}',
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: _showAddPictureDialog,
              child: Text('Post Picture'),
            ),
            ElevatedButton(
              onPressed: () {
                _navigateToManagePictures(context);
              },
              child: Text('View Posts'),
            ),
          ],
        ),
      ),
    );
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  Future<void> _addPicture(String imagePath) async {
    try {
      await pictures.add({
        'imagePath': imagePath,
        'comments': [], 
      });
      print('Picture posted successfully.');
    } catch (e) {
      print('Error posting picture: $e');
    }
  }

  void _showAddPictureDialog() {
    String imagePath = ''; 

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Post Picture'),
          content: TextField(
            onChanged: (value) => imagePath = value,
            decoration: InputDecoration(labelText: 'Image URL'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addPicture(imagePath); 
                Navigator.pop(context);
              },
              child: Text('Post'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToManagePictures(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagePicturesPage(),
      ),
    );
  }
}

class ManagePicturesPage extends StatelessWidget {
  final CollectionReference pictures =
  FirebaseFirestore.instance.collection('pictures');

  Future<void> _deletePicture(String pictureId) async {
    try {
      await pictures.doc(pictureId).delete();
      print('Picture deleted successfully.');
    } catch (e) {
      print('Error deleting picture: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, String pictureId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Picture'),
          content: Text('Are you sure you want to delete this picture?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deletePicture(pictureId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pictures.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data!.docs.map((picture) {
                return ListTile(
                  title: Image.network(picture['imagePath']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(context, picture.id),
                  ),
                  onTap: () => _navigateToComments(context, picture.id),
                );
              }).toList(),
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  void _navigateToComments(BuildContext context, String pictureId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(pictureId: pictureId),
      ),
    );
  }
}

class CommentsPage extends StatefulWidget {
  final String pictureId;

  CommentsPage({required this.pictureId});

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final CollectionReference pictures =
  FirebaseFirestore.instance.collection('pictures');
  final TextEditingController commentController = TextEditingController();

  Future<void> _deleteComment(String pictureId, String comment) async {
    try {
      await pictures.doc(pictureId).update({
        'comments': FieldValue.arrayRemove([comment]),
      });
      print('Comment deleted successfully.');
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: pictures.doc(widget.pictureId).snapshots(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasData) {
                  var pictureData = snapshot.data!;
                  var comments = pictureData['comments'] as List<dynamic>;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      var comment = comments[index];
                      return ListTile(
                        title: Text(comment),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _showDeleteConfirmation(context, comment),
                        ),
                      );
                    },
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(labelText: 'Add a comment'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addComment,
                  child: Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addComment() async {
    String comment = commentController.text.trim();
    if (comment.isNotEmpty) {
      try {
        await pictures.doc(widget.pictureId).update({
          'comments': FieldValue.arrayUnion([comment]),
        });
        print('Comment posted successfully.');
        commentController.clear();
      } catch (e) {
        print('Error posting comment: $e');
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, String comment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteComment(widget.pictureId, comment);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
