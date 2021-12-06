import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

FirebaseAuth auth = FirebaseAuth.instance;

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();
  @override
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
              //print('You have an error! ${snapshot.error.toString()}');
              return const Text('Something went wrong!');
            } else if (snapshot.hasData) {
              return const Auth();
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
  const CreateTask({Key? key}) : super(key: key);

  @override
  _CreateTaskState createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> {
  final _formKey = GlobalKey<FormState>();
  final taskController = TextEditingController();
  final dateController = TextEditingController();
  final dbRef = FirebaseDatabase.instance.reference().child("tasks");
  User? usr = auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
            child: Column(children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextFormField(
              controller: taskController,
              decoration: InputDecoration(
                labelText: "Enter Task",
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Enter Task';
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextFormField(
              keyboardType: TextInputType.datetime,
              controller: dateController,
              onTap: () async {
                var date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100));
                dateController.text = date.toString().substring(0, 10);
              },
              decoration: InputDecoration(
                labelText: "Enter Due Date",
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Enter Due Date';
                }
                return null;
              },
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        dbRef.push().set({
                          "User": usr!.email,
                          "TaskName": taskController.text,
                          "DueDate": dateController.text,
                          "Status": "active",
                        }).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Successfully Added')));
                          dateController.clear();
                          taskController.clear();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const MyHomePage(title: "Current Tasks")),
                          );
                        }).catchError((onError) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(onError)));
                        });
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              )),
        ])));
  }

  @override
  void dispose() {
    super.dispose();
    dateController.dispose();
    taskController.dispose();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final dbRef = FirebaseDatabase.instance.reference().child("tasks");
  static var lists = [];
  static User? usr = auth.currentUser;
  final taskController = TextEditingController();

  appSignOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Auth()),
    );
  }

  editTask(values, taskName, taskDate) {
    return Scaffold(
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
          TextField(
            decoration: InputDecoration(hintText: taskName),
            controller: taskController,
          ),
          ElevatedButton(
              onPressed: () =>
                  updateTask(values, taskName, taskController.text, taskDate),
              child: const Text('Submit')),
        ])));
  }

  updateTask(values, taskName, newTaskName, taskDate) {
    Map<String, dynamic> childrenPathValueMap = {};
    values.forEach((key, values) {
      if (values["User"] == usr!.email &&
          taskName == values["TaskName"] &&
          taskDate == values["DueDate"]) {
        childrenPathValueMap["$key/TaskName"] = newTaskName;
      }
    });
    dbRef.update(childrenPathValueMap);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Taskify')),
    );
  }

  markCompleted(values, taskName, taskDate) {
    Map<String, dynamic> childrenPathValueMap = {};
    values.forEach((key, values) {
      if (values["User"] == usr!.email &&
          taskName == values["TaskName"] &&
          taskDate == values["DueDate"]) {
        childrenPathValueMap["$key/Status"] = "complete";
      }
    });
    dbRef.update(childrenPathValueMap);
  }

  markActive(values, taskName, taskDate) {
    Map<String, dynamic> childrenPathValueMap = {};
    values.forEach((key, values) {
      if (values["User"] == usr!.email &&
          taskName == values["TaskName"] &&
          taskDate == values["DueDate"]) {
        childrenPathValueMap["$key/Status"] = "active";
      }
    });
    dbRef.update(childrenPathValueMap);
  }

  carphins() {
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
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MyHomePage(title: "Taskify")));
                  },
                  child: const Text('View Active Tasks')),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => viewCompleted()));
                  },
                  child: const Text('View Completed Tasks')),
              ElevatedButton(
                  onPressed: appSignOut, child: const Text('Sign Out')),
            ],
          ),
        ),
      ),
    );
  }

  viewCompleted() {
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
              FutureBuilder(
                  future: dbRef.orderByChild("DueDate").startAt("0").once(),
                  builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                    if (snapshot.hasData) {
                      lists.clear();
                      Map<dynamic, dynamic> values = snapshot.data!.value;
                      values.forEach((key, values) {
                        if (values["User"] == usr!.email &&
                            values["Status"] == "complete") {
                          lists.add(values);
                        }
                      });
                      return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: lists.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                    child: InkWell(
                                  splashColor: Colors.blue.withAlpha(30),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => editTask(
                                              values,
                                              lists[index]["TaskName"],
                                              lists[index]["DueDate"])),
                                    );
                                  },
                                  onDoubleTap: () {
                                    markActive(values, lists[index]["TaskName"],
                                        lists[index]["DueDate"]);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                viewCompleted()));
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(lists[index]["TaskName"]),
                                      Text("Due Date: " +
                                          lists[index]["DueDate"]),
                                    ],
                                  ),
                                ));
                              }));
                    }
                    return const CircularProgressIndicator();
                  }),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MyHomePage(title: "Taskify")));
                  },
                  child: const Text('View Active Tasks')),
              ElevatedButton(
                  onPressed: carphins, child: const Text('Carphins')),
              ElevatedButton(
                  onPressed: appSignOut, child: const Text('Sign Out')),
            ],
          ),
        ),
      ),
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
              FutureBuilder(
                  future: dbRef.orderByChild("DueDate").startAt("0").once(),
                  builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                    if (snapshot.hasData) {
                      lists.clear();
                      Map<dynamic, dynamic> values = snapshot.data!.value;
                      values.forEach((key, values) {
                        if (values["User"] == usr!.email &&
                            values["Status"] == "active") {
                          lists.add(values);
                        }
                      });
                      return ListView.builder(
                          shrinkWrap: true,
                          itemCount: lists.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                                child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => editTask(
                                          values,
                                          lists[index]["TaskName"],
                                          lists[index]["DueDate"])),
                                );
                              },
                              onDoubleTap: () {
                                markCompleted(values, lists[index]["TaskName"],
                                    lists[index]["DueDate"]);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const MyHomePage(title: 'Taskify')),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(lists[index]["TaskName"]),
                                  Text("Due Date: " + lists[index]["DueDate"]),
                                ],
                              ),
                            ));
                          });
                    }
                    return const CircularProgressIndicator();
                  }),
              const CreateTask(),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => viewCompleted()));
                  },
                  child: const Text('View Completed Tasks')),
              ElevatedButton(
                  onPressed: appSignOut, child: const Text('Sign Out')),
            ],
          ),
        ),
      ),
    );
  }
}

class Auth extends StatefulWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final myController = TextEditingController();
  final myController2 = TextEditingController();
  appRegister(String uEmail, String uPass) async {
    try {
      // ignore: unused_local_variable
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: uEmail, password: uPass);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        const Text('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        const Text('The account already exists for that email.');
      }
    } catch (e) {
      //print(e);
    }
    auth.authStateChanges().listen((User? user) {
      if (user == null) {
        //print('User is currently signed out!');
      } else {
        //print('User is signed in!');
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
        const Text('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        const Text('Wrong password provided for that user.');
      }
    }
    auth.authStateChanges().listen((User? user) {
      if (user == null) {
        //print('User is currently signed out!');
      } else {
        //print('User is signed in!');
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
