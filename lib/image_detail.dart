import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class SignaturePainter extends CustomPainter {
  SignaturePainter(this.image,this.width,this.height);
  var image;
  double width;
  double height;

  void paint(Canvas canvas, Size size) {
    if(image!=null){
      Paint paint = new Paint();
      double dwidth = 0;
      double dheight = 0;
      if (image.width.toDouble() / width > image.height.toDouble() / height) {
        dwidth = width;
        dheight = image.height.toDouble() * dwidth / image.width.toDouble();
      }
      else {
        dheight = height;
        dwidth = image.width.toDouble() * dheight / image.height.toDouble();
      }
      var source = Rect.fromLTWH(0, 0, this.image.width.toDouble(), this.image.height.toDouble());
      var dest = Rect.fromLTWH((width-dwidth)/2,(height-dheight)/2,dwidth,dheight);

      paint.color =Colors.red;
      canvas.drawImageRect(image, source, dest, paint);
    }
  }
  bool shouldRepaint(SignaturePainter other){
    return true;
  }
}
class ImageDetailPage extends StatefulWidget {
  ImageDetailPage({Key key, this.title,this.image}) : super(key: key);
  final String title;
  var image;
  @override
  _ImageDetailPageState createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage> {
  final GlobalKey globalKey = new GlobalKey();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(widget.image.width.toDouble());
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
   double  width = MediaQuery.of(context).size.width;
   double  height = MediaQuery.of(context).size.height;
    return Container(
        child: Stack(
          children: [
            RepaintBoundary(
              key: globalKey,
              child:  CustomPaint(painter: new SignaturePainter(widget.image,width,height),size:Size(widget.image.width.toDouble(),widget.image.height.toDouble()) ,),
            ),
            Container(
              child:    RaisedButton(
                child: Text("Save to local"),
                onPressed: (){
                  _capturePng();
                },
              ),
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.only(bottom: 20),
            ),


          ],),
      color: Colors.white,
      padding: EdgeInsets.all(0),
    );
  }

  Future<void> _capturePng() async {
    RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
    var image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    print(pngBytes);
    getApplicationDocumentsDirectory().then((dir){
      String path = dir.path +"/test.png";
      new File(path).writeAsBytesSync(pngBytes);
      _showPathDialog(path);
    });
  }



  Future<void> _showPathDialog(String path) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save success'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Image is save in ${path}'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('exit'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}