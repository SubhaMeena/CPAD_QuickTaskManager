
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keyApplicationId = 'aMTLNbwfeEtXWkjySuXz41JgHUuPTgpZJ67VWJIm';
  final keyClientKey = 'bl7hZRT2r8z35BCoomcvu6ufaXqDG2VmT8jE5EsZ';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl, clientKey: keyClientKey, debug: true);

  runApp(MyApp());
}

class Tasks {
  final String objectId;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tasks({
    required this.objectId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

class TaskListScreen extends StatefulWidget {
  final Function refreshTaskList;

  TaskListScreen({required this.refreshTaskList});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Tasks> tasks = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<void> refresh() async {
    await fetchTasks();
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> fetchTasks() async {
    final QueryBuilder<ParseObject> queryBuilder = QueryBuilder<ParseObject>(ParseObject('Tasks'))
      ..whereEqualTo('status', 'todo')
      ..orderByAscending('createdAt');

    final QueryBuilder<ParseObject> completedTasksQuery = QueryBuilder<ParseObject>(ParseObject('Tasks'))
      ..whereEqualTo('status', 'complete')
      ..orderByDescending('updatedAt');

    final response = await queryBuilder.query();
    final completedTasksResponse = await completedTasksQuery.query();

    List<Tasks> myTasks = [];
    List<Tasks> completedTasks = [];

    if (response.success && response.results != null) {
      myTasks = response.results!.map((parseObject) {
        return Tasks(
          objectId: parseObject.objectId,
          title: parseObject.get('title') ?? '',
          description: parseObject.get('description') ?? '',
          status: parseObject.get('status') ?? '',
          createdAt: parseObject.get('createdAt') ?? DateTime.now(),
          updatedAt: parseObject.get('updatedAt') ?? DateTime.now(),
        );
      }).toList();
    }

    if (completedTasksResponse.success && completedTasksResponse.results != null) {
      completedTasks = completedTasksResponse.results!.map((parseObject) {
        return Tasks(
          objectId: parseObject.objectId,
          title: parseObject.get('title') ?? '',
          description: parseObject.get('description') ?? '',
          status: parseObject.get('status') ?? '',
          createdAt: parseObject.get('createdAt') ?? DateTime.now(),
          updatedAt: parseObject.get('updatedAt') ?? DateTime.now(),
        );
      }).toList();
    }

    setState(() {
      tasks = myTasks + completedTasks;
    });
  }

  Future<void> toggleTaskStatus(Tasks task) async {
    final newStatus = (task.status == 'todo') ? 'complete' : 'todo';

    final updatedTaskObject = ParseObject('Tasks')
      ..objectId = task.objectId
      ..set('status', newStatus)
      ..set('updatedAt', DateTime.now());

    final response = await updatedTaskObject.save();

    if (response.success) {
      await fetchTasks();
    } else {
      print('Error: ${response.error?.message}');
    }
  }

  Future<void> deleteTask(Tasks task) async {
    final confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Delete Task?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final response = await ParseObject('Tasks').delete(id: task.objectId);

      if (response.success) {
        setState(() {
          tasks.remove(task);
        });
      } else {
        print('Error: ${response.error?.message}');
      }
    }
  }

  void navigateToTaskUpdateScreen(Tasks task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskUpdateScreen(
          task: task,
          updateTask: updateTask,
        ),
      ),
    );
  }

  Future<void> updateTask() async {
    await fetchTasks();
    await Future.delayed(Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.lightBlueAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text(
          'My Tasks',
          style: TextStyle(fontSize:25,color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () {
          return refresh();
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    Color tileColor;
                    TextStyle titleStyle;
                    TextStyle subtitleStyle;

                    if (task.status == 'complete') {
                      tileColor = Colors.grey;
                      titleStyle = TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                      );
                      subtitleStyle = TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                      );
                    } else {
                      tileColor = Colors.white24;
                      titleStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
                      subtitleStyle = TextStyle(fontSize: 16);
                    }

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(
                          task.title,
                          style: titleStyle,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.description,
                              style: subtitleStyle,
                            ),
                        //  Text(
                          //  'Status: ${task.status}',
                            //style: TextStyle(fontSize: 16),
                          //),
                      //    Text(
                        //    'Date: ${DateFormat('dd-MMMM-yy').format(task.createdAt)}',
                          //  style: TextStyle(fontSize: 16),
                         // ),
                        ],
                      ),
                        tileColor: tileColor,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                                value: task.status == 'complete',
                                onChanged: (bool? value) {
                                  toggleTaskStatus(task);},
                              ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                navigateToTaskUpdateScreen(task);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                deleteTask(task);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsScreen(task: task),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.pinkAccent,
              child: Center(
                child: Text(
                  'Task Management App 2023',
                  style: TextStyle(fontSize:20,color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskCreationScreen(
                refreshTaskList: refresh,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskDetailsScreen extends StatelessWidget {
  final Tasks task;

  TaskDetailsScreen({required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              task.description,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
           Text(
             'Status: ${task.status}',
             style: TextStyle(fontSize: 16),
            ),
            Text(
              'Date: ${DateFormat('DD-MON-YY').format(task.createdAt)}',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCreationScreen extends StatefulWidget {
  final Function refreshTaskList;

  TaskCreationScreen({required this.refreshTaskList});

  @override
  _TaskCreationScreenState createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Future<void> createTask() async {
    final ParseObject newTaskObject = ParseObject('Tasks')
      ..set('title', titleController.text)
      ..set('description', descriptionController.text)
      ..set('status', 'todo')
      ..set('createdAt', DateTime.now())
      ..set('updatedAt', DateTime.now());

    final response = await newTaskObject.save();

    if (response.success) {
      widget.refreshTaskList();
      Navigator.pop(context);
    } else {
      print('Error: ${response.error?.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Task Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Task Description'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: createTask,
              child: Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskUpdateScreen extends StatefulWidget {
  final Tasks task;
  final Function updateTask;

  TaskUpdateScreen({
    required this.task,
    required this.updateTask,
  });

  @override
  _TaskUpdateScreenState createState() => _TaskUpdateScreenState();
}

class _TaskUpdateScreenState extends State<TaskUpdateScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(text: widget.task.description);
  }

  Future<void> performUpdate() async {
    final ParseObject updatedTaskObject = ParseObject('Tasks')
      ..objectId = widget.task.objectId
      ..set('title', titleController.text)
      ..set('description', descriptionController.text)
      ..set('updatedAt', DateTime.now());

    final response = await updatedTaskObject.save();

    if (response.success) {
      widget.updateTask();
      Navigator.pop(context);
    } else {
      print('Error: ${response.error?.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Task Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Task Description'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                performUpdate();
              },
              child: Text('Edit Task'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager App',
	  debugShowCheckedModeBanner: false,
      home: TaskListScreen(
        refreshTaskList: () {},
    ),
    );
  }
}
