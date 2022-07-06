import 'package:appartapp/classes/runtime_store.dart';
import 'package:appartapp/widgets/error_dialog_builder.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class EditPassword extends StatefulWidget {
  Color bgColor = Colors.white;
  String urlStr =
      "http://ratti.dynv6.net/appartapp-1.0-SNAPSHOT/api/reserved/editsensitive";

  @override
  _EditPasswordState createState() => _EditPasswordState();
}

class _EditPasswordState extends State<EditPassword> {
  final oldPasswordController = TextEditingController();
  final password1Controller = TextEditingController();
  final password2Controller = TextEditingController();

  String status = "";

  bool _isLoading = false;

  void doUpdate(String email, String oldpassword, String newpassword) async {
    var dio = RuntimeStore().dio; //ok
    try {
      Response response = await dio.post(
        widget.urlStr,
        data: {"password": oldpassword, "newpassword": newpassword},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
        ),
      );

      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        Navigator.restorablePush(
            context, ErrorDialogBuilder.buildGenericConnectionErrorRoute);
      }
    } on DioError {
      Navigator.restorablePush(
          context, ErrorDialogBuilder.buildConnectionErrorRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Modifica password'),
          backgroundColor: Colors.brown,
        ),
        backgroundColor: widget.bgColor,
        body: ListView(padding: EdgeInsets.all(16.0), children: <Widget>[
          Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Inserisci la tua password attuale")),
          Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password attuale',
                ),
                controller: oldPasswordController,
              )),
          const Divider(
            height: 20,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: Colors.grey,
          ),
          Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("La tua nuova password?")),
          Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nuova password',
                ),
                controller: password1Controller,
              )),
          Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Conferma la tua nuova password")),
          Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Conferma password',
                ),
                controller: password2Controller,
              )),
          ElevatedButton(
              child: Text("Aggiorna"),
              style: ElevatedButton.styleFrom(primary: Colors.brown),
              onPressed: () {
                String oldPassword = oldPasswordController.text;
                if (oldPasswordController.text.trim().isEmpty ||
                    password1Controller.text.trim().isEmpty ||
                    password2Controller.text.trim().isEmpty) {
                  setState(() {
                    status = "Inserisci la tua vecchia password e la nuova";
                  });
                  return;
                }

                if (password1Controller.text != password2Controller.text) {
                  setState(() {
                    status = "Le password non corrispondono";
                  });
                } else {
                  String newPassword = password1Controller.text;
                  setState(() {
                    _isLoading = true;
                  });
                  doUpdate(RuntimeStore().getUser()?.email ?? "", oldPassword,
                      newPassword);
                }
              }),
          Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                status,
                style: TextStyle(fontSize: 20),
              )),
        ]));
  }
}
