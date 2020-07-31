import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:async/async.dart';

class PickImage extends StatefulWidget {
  @override
  _PickImageState createState() => _PickImageState();
}

class _PickImageState extends State<PickImage> {
  File _selectedFile;
  bool _inProcess = false;
  var _predict = "";
  var _result = "";
  var txt = TextEditingController();
  Widget getImageWidget() {
    if (_selectedFile != null) {
      return Image.file(
        _selectedFile,
        height: 250,
        fit: BoxFit.scaleDown,
      );
    } else {
      return Image.asset(
        "assets/placeholder.jpg",
        width: 250,
        height: 250,
        fit: BoxFit.cover,
      );
    }
  }

  getImage(ImageSource source) async {
    File image = await ImagePicker.pickImage(source: source);
    if (image != null) {
      File cropped = await ImageCropper.cropImage(
          sourcePath: image.path,
//          aspectRatio: CropAspectRatio(
//              ratioX: 1, ratioY: 1),
//          compressQuality: 100,
//          maxWidth: 700,
//          maxHeight: 700,
          compressFormat: ImageCompressFormat.jpg,
          androidUiSettings: AndroidUiSettings(
            toolbarColor: Colors.deepOrange,
            toolbarTitle: "RPS Cropper",
            statusBarColor: Colors.deepOrange.shade900,
            backgroundColor: Colors.white,
          ));
      this.setState(() {
        _selectedFile = cropped;
        _inProcess = false;
      });
    } else {
      this.setState(() {
        _inProcess = false;
      });
    }
  }

  upload(File imageFile) async {
    // open a bytestream
    // ignore: deprecated_member_use
    // File imageFile = new File("../3.PNG");
    if (imageFile.existsSync()) {
      var stream =
          // ignore: deprecated_member_use
          new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
      // get file length
      var length = await imageFile.length();

      // string to uri
      var uri = Uri.parse("http://13.76.102.220:5000/");

      // create multipart request
      var request = new http.MultipartRequest("POST", uri);

      // multipart that takes file
      var multipartFile = new http.MultipartFile('image', stream, length,
          filename: basename(imageFile.path));

      // add file to multipart
      request.files.add(multipartFile);

      // send
      var response = await request.send();
      print(response.statusCode);

      // listen for response
      response.stream
          .asBroadcastStream()
          .transform(utf8.decoder)
          .listen((value) {
        this.setState(() {
          _predict = value;
          String str = _predict;
          String result = str.substring(15, str.lastIndexOf('"'));
          _result = result;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("NTD_OCR"),
        ),
        body: ListView(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                getImageWidget(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    MaterialButton(
                        color: Colors.green,
                        child: Text(
                          "Camera",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          getImage(ImageSource.camera);
                        }),
                    MaterialButton(
                        color: Colors.deepOrange,
                        child: Text(
                          "Gallery",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          getImage(ImageSource.gallery);
                        }),
                  ],
                )
              ],
            ),
            MaterialButton(
                color: Colors.blueAccent,
                child: Text(
                  "Predict",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  upload(_selectedFile);
                  txt.text = _result;
                }),
            Container(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: TextField(
                  controller: txt,
                  minLines: 1,
                  maxLines: 7,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Insert your image above',
                    filled: true,
                    fillColor: Color(0xFFDBEDFF),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            (_inProcess)
                ? Container(
                    color: Colors.white,
                    height: MediaQuery.of(context).size.height * 0.95,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Center()
          ],
        ));
  }
}
