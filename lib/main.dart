import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    var materialApp = MaterialApp(
      title: 'MY APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TasksPageWidget(),
    );
    return materialApp;
  }
} 

class Tasks {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  static Future<List<TaskOpj>> allTasks() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getAllTasks();
    return List.generate(maps.length, (i) {
      return TaskOpj.fromJson(maps[i]);
    });
  }

  static Future<TaskOpj> getTask(String id) async {
    final Map<String, dynamic> map = await _dbHelper.getTask(id);
    if (map == null) {
      throw Exception('Task not found');
    }
    return TaskOpj.fromJson(map);
  }

  static Future<TaskOpj> createTask(TaskOpj opj) async {
    await _dbHelper.insertTask(opj.toJson());
    return opj;
  }

  static Future<bool> updateTask(TaskOpj opj) async {
    final int result = await _dbHelper.updateTask(opj.toJson());
    return result > 0;
  }

  static Future deleteTask(String id) async {
    final int result = await _dbHelper.deleteTask(id);
    if (result == 0) {
      throw Exception('Failed to delete task');
    }
  }
}

class TaskOpj {
  String guid;
  String note;
  String createdAt;
  String modfiledAt;

  TaskOpj({this.guid, this.note, this.createdAt, this.modfiledAt});

  TaskOpj.fromJson(Map<String, dynamic> json) {
    guid = json['guid'];
    note = json['note'];
    createdAt = json['createdAt'];
    modfiledAt = json['modfiledAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['guid'] = this.guid;
    data['note'] = this.note;
    data['createdAt'] = this.createdAt;
    data['modfiledAt'] = this.modfiledAt;
    return data;
  }
}
 
class TasksPageWidget extends StatefulWidget {
  @override
  _TasksPageWidgetState createState() => _TasksPageWidgetState();
}

class _TasksPageWidgetState extends State<TasksPageWidget> {
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future refresh() async {
    tasks = await Tasks.allTasks();
    setState(() {});
  }

  var tasks = List<TaskOpj>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => refresh(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) => TaskWidget(
          taskOpj: tasks[index],
          notifyParent: refresh,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return TaskAddPageWidget(
                notifyParent: refresh,
              );
            },
          ),
        ),
        tooltip: 'add',
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskWidget extends StatelessWidget {
  final TaskOpj taskOpj;
  final Function() notifyParent;
  TaskWidget({Key key, @required this.taskOpj, @required this.notifyParent})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20.0,
        bottom: 0.0,
      ),
      child: new Card(
        child: ListTile(
          leading: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return TaskEditPageWidget(
                    taskOpj: taskOpj,
                    notifyParent: notifyParent,
                  );
                },
              ),
            ),
          ),
          title: Text(taskOpj.note),
          subtitle: Text(taskOpj.guid),
          trailing: new IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              await Tasks.deleteTask(taskOpj.guid);
              Scaffold.of(context).hideCurrentSnackBar();
              Scaffold.of(context).showSnackBar(new SnackBar(
                content: new Text("Deleted note : " + taskOpj.guid),
              ));
              if (notifyParent != null) notifyParent();
            },
          ),
        ),
      ),
    );
  }
}

class TaskEditPageWidget extends StatefulWidget {
  final Function() notifyParent;
  final TaskOpj taskOpj;
  TaskEditPageWidget(
      {Key key, @required this.taskOpj, @required this.notifyParent})
      : super(key: key);

  @override
  _TaskEditPageWidgetState createState() => _TaskEditPageWidgetState();
}

class _TaskEditPageWidgetState extends State<TaskEditPageWidget> {
  TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController.fromValue(
      TextEditingValue(
        text: widget.taskOpj.note,
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
    );
  }

  Widget _appBar() {
    return AppBar(
      title: new Text("Edit Task"),
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.save),
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Text("Note:"),
          TextField(
              decoration: InputDecoration(border: InputBorder.none),
              autofocus: true,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              controller: _noteController),
        ],
      ),
    );
  }

  Future _save() async {
    widget.taskOpj.note = _noteController.text;
    await Tasks.updateTask(widget.taskOpj);
    widget.notifyParent();
    Navigator.pop(context);
  }
}

class TaskAddPageWidget extends StatefulWidget {
  final Function() notifyParent;
  TaskAddPageWidget({Key key, @required this.notifyParent}) : super(key: key);
  @override
  _TaskAddPageWidgetState createState() => _TaskAddPageWidgetState();
}

class _TaskAddPageWidgetState extends State<TaskAddPageWidget> {
  TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
    );
  }

  Widget _appBar() {
    return AppBar(
      title: new Text("Add Task"),
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.save),
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Text("Note:"),
          TextField(
              decoration: InputDecoration(border: InputBorder.none),
              autofocus: true,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              controller: _noteController),
        ],
      ),
    );
  }

  Future _save() async {
    var taskOpj = TaskOpj();
    taskOpj.note = _noteController.text;
    await Tasks.createTask(taskOpj);
    widget.notifyParent();
    Navigator.pop(context);
  }
}
