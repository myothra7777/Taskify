//import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

//Define auth (got errors when this was moved into app class)
FirebaseAuth auth = FirebaseAuth.instance;

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Taskify',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FutureBuilder(
          future: _fbApp,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('You have an error! ${snapshot.error.toString()}');
              return const Text('Something went wrong!');
            } else if (snapshot.hasData) {
              return Page2();
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ));
  }
}

class CreateTask extends StatefulWidget {
  CreateTask({Key? key}) : super(key: key); //added required

  @override
  _CreateTaskState createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final dbRef = FirebaseDatabase.instance.reference().child("tasks");

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
            child: Column(children: <Widget>[
          Padding(
            padding: EdgeInsets.all(20.0),
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Enter Task",
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              // The validator receives the text that the user has entered.
              validator: (value) {
                if (value!.isEmpty) {
                  //Added !
                  return 'Enter Task';
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: TextFormField(
              keyboardType: TextInputType.datetime,
              controller: ageController,
              decoration: InputDecoration(
                labelText: "Enter Due Date",
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              // The validator receives the text that the user has entered.
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Enter Due Date';
                }
                return null;
              },
            ),
          ),
          Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        //Added !
                        dbRef.push().set({
                          "TaskName": nameController.text,
                          "DueDate": ageController.text,
                        }).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Successfully Added')));
                          ageController.clear();
                          nameController.clear();
                        }).catchError((onError) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(onError)));
                        });
                      }
                    },
                    child: Text('Submit'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MyHomePage(title: "Home Page")),
                      );
                    },
                    child: Text('Refresh'),
                  ),
                ],
              )),
        ])));
  }

  @override
  void dispose() {
    super.dispose();
    ageController.dispose();
    nameController.dispose();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dbRef = FirebaseDatabase.instance.reference().child("tasks");
  var lists = [];

  appSignOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Page2()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Current Tasks:',
                style: TextStyle(
                    fontWeight: FontWeight.w200,
                    fontSize: 30,
                    fontFamily: 'Roboto',
                    fontStyle: FontStyle.italic),
              ),
              FutureBuilder(
                  future: dbRef.once(),
                  builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                    if (snapshot.hasData) {
                      lists.clear();
                      Map<dynamic, dynamic> values = snapshot.data!.value;
                      values.forEach((key, values) {
                        lists.add(values);
                      });
                      return new ListView.builder(
                          shrinkWrap: true,
                          itemCount: lists.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(lists[index]["TaskName"]),
                                  Text("Due Date: " + lists[index]["DueDate"]),
                                ],
                              ),
                            );
                          });
                    }
                    return CircularProgressIndicator();
                  }),
              CreateTask(),
              ElevatedButton(
                  onPressed: appSignOut, child: const Text('Sign Out')),
            ],
          ),
        ),
      ),
    );
  }
}

class Page2 extends StatefulWidget {
  const Page2({Key? key}) : super(key: key);

  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  final myController = TextEditingController();
  final myController2 = TextEditingController();
  appRegister(String uEmail, String uPass) async {
    try {
      // ignore: unused_local_variable
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: uEmail, password: uPass);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
    auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Taskify')),
        );
      }
    });
  }

  appSignIn(String uEmail, String uPass) async {
    try {
      // ignore: unused_local_variable
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: uEmail, password: uPass);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
    auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Taskify')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Sign Up'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(labelText: 'Enter Email'),
              controller: myController,
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Enter Password'),
              controller: myController2,
            ),
            ElevatedButton(
                onPressed: () =>
                    appRegister(myController.text, myController2.text),
                child: const Text('Register')),
            ElevatedButton(
                onPressed: () =>
                    appSignIn(myController.text, myController2.text),
                child: const Text('Sign In'))
          ],
        ),
      ),
    );
  }
}
