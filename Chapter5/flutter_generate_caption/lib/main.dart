// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'home.dart';

// List<CameraDescription> cameras;

// main() {
//   runApp(new MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'tflite real-time detection',
//       theme: ThemeData(
//         brightness: Brightness.dark,
//       ),
//       home: Home(),
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart'  as http;
import 'package:dio/dio.dart';
import 'dart:convert';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;

  @override
  void initState() {
    
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      const oneSec = const Duration(seconds:5);
      new Timer.periodic(oneSec, (Timer t) => takePics());
    });
  }

 takePics() async {
   print("TAKE PICS CALLED");
  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';
    controller.takePicture(filePath).then((_){
      print('FILE PATH:: ${filePath}');
    var s = Image.file(File(filePath));
    File f = File(filePath);
    String base64Image = base64Encode(f.readAsBytesSync());
    print('IMAGE FILE:  $s');
    //getResponse(filePath);
    responsive(f);
    });
    

}

Future<void> responsive(File img) async {
    var url = 'http://api-os-max.apps.us-east-2.starter.openshift-online.com/model/predict';
    Map<String, String> headers = {"accept": "application/json", "Content-Type": "multipart/form-data"};
    String base64Image = base64Encode(img.readAsBytesSync());
    String js = '{"image": ${img}, "type":"image/jpg"}';  // make POST request
    final response = await http.post(url, headers: headers, body: js);
    var j = json.decode(response.body);
    print('RESPONSE : ${response.statusCode} , ${response.body}');
}


Future<void> getResponse (String f) async {
  var url = 'http://api-os-max.apps.us-east-2.starter.openshift-online.com/model/predict';

  // Map<String, String> headers = {"Content-type": "application/json"};
  // String json = 'image=@${f}';  // make POST request
  // Response response = await post(url, headers: headers, body: json);  // check the status code for the result
  // int statusCode = response.statusCode;
  // post
  // print('GETTING RESPONSE: ${statusCode}');


  // var d = dio.Dio();
  // dio.FormData formData = new dio.FormData.fromMap({
  //  "image": f
  // });
  // print('BEFORE RESPONSE');
  // var response;
  // try{
  // response = await d.post(url, data: formData,).then((_){
  //   print("RESPONSE IN: $response");
  // });
  // } catch(e) {
  //   print("Response:: ${response}");
  //   print('Exception:: ${e.toString()}');
  // }
  // print('AFTER RESPONSE');


  Dio dio = new Dio();
  FormData formdata = new FormData();
  Map<String, String> headers = {"accept": "application/json", "Content-Type":"multipart/form-data"};


  FormData formData = FormData.fromMap({

    "image": await MultipartFile.fromFile(f)
});
final response= await dio.post(url, data: formData);

  // formdata.add("image", new UploadFileInfo(f, basename(f.path)));
  // String js = '{"image":${f}}';
  // final response =
  //     await http.post(url, headers: headers, body: js);
   print("RESPONSE CODE ${response.statusCode}");
   var j = json.decode(response.data);
    print('RESPONSE:: ${j}');

}


  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
        aspectRatio:
        controller.value.aspectRatio,
        child: CameraPreview(controller));
  }
}