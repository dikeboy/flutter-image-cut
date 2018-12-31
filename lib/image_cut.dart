import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:ui' as flutterui;
import 'package:flutter/rendering.dart' as ui;
import 'package:flutter/services.dart' as ui;
import 'package:flutter/widgets.dart' as ui;
import 'package:flutter/material.dart' as ui;
import 'package:flutter/painting.dart' as ui;
import 'package:image_cut/image_detail.dart';



class ImageLoader {
  static ui.AssetBundle getAssetBundle() => (ui.rootBundle != null)
      ? ui.rootBundle
      : new ui.NetworkAssetBundle(new Uri.directory(Uri.base.origin));
  /**
   * convert to painting.Image
   */
  static Future<flutterui.Image> load(String url) async {
    ui.ImageStream stream = new ui.AssetImage(url, bundle: getAssetBundle())
        .resolve(ui.ImageConfiguration.empty);
    Completer<flutterui.Image> completer = new Completer<flutterui.Image>();
    void listener(ui.ImageInfo frame, bool synchronousCall) {
      final flutterui.Image image = frame.image;
      completer.complete(image);
      stream.removeListener(listener);
    }

    stream.addListener(listener);
    return completer.future;
  }
}
class SignaturePainter extends CustomPainter {
  SignaturePainter(this.points,  this.width, this.height,
      this.cWidth, this.cHeight, this.image);
  double cWidth = 200;  //clip square width
  double cHeight = 200;  //clip square height
  double width;  //total width
  double height; //total height
  flutterui.Image image; // source image

  final List<Offset> points; //point[0] touchDown offset, point[1] touchMoveOffset  point[2] clip square start offset, point[3],image draw size

  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = Colors.blue[200]
      ..isAntiAlias = true
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.bevel;
    if (image != null) {
      //draw the backgroud image
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
      if (points.length > 0) {
        points[3] = Offset(dwidth, dheight);
      }
      canvas.drawImageRect(image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH((width - dwidth) / 2,
              (height - dheight) / 2, dwidth, dheight), paint);
    }

      double startX = points[1].dx - points[0].dx + points[2].dx;
      double startY = points[1].dy - points[0].dy + points[2].dy;
      if (startX < 0)
        startX = 0;
      else if (startX + cWidth > width) {
        startX = width - cWidth;
      }
      if (startY < 0)
        startY = 0;
      else if (startY + cHeight > height) {
        startY = height - cHeight;
      }
//      canvas.drawRect(Rect.fromLTRB(startX,startY,startX+200,startY+200), paint);
      List<Offset> points2 = [
        Offset(startX, startY),
        Offset(startX + cWidth, startY),
        Offset(startX + cWidth, startY + cHeight),
        Offset(startX, startY + cHeight),
        Offset(startX, startY),
      ];
      canvas.drawPoints(PointMode.polygon, points2, paint);//draw the clip box
      paint.color = Colors.red;
//      paint..style=PaintingStyle.stroke;
      double radius = 10;
      canvas.drawCircle(points2[0],radius,paint);  //draw the drag point
      canvas.drawCircle(points2[1],radius,paint);
      canvas.drawCircle(points2[2],radius,paint);
//      canvas.drawLine(Offset(points2[2].dx-radius, points2[2].dy-radius), Offset(points2[2].dx+radius, points2[2].dy+radius), paint);
      canvas.drawCircle(points2[3],radius,paint);

  }
  bool shouldRepaint(SignaturePainter other){
    return true;
  }


}
class ImageCutPage extends StatefulWidget {
  ImageCutPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _ImageCutPageState createState() => _ImageCutPageState();
}
///clip point position
enum DownPosition{
  LEFT_UP,
  RIGHT_UP,
  LEFT_DOWN,
  RIGHT_DOWN
}
class _ImageCutPageState extends State<ImageCutPage> {
  List<Offset> _points = <Offset>[];
  double width=0;
  double height =0;
  double cWidth =200;
  double cHeight =200;
  double dHeight;
  double dWidth;
  bool  isDrag = true;
  bool  first = true;
  var image;
  DownPosition downPosition;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _points.add(Offset(0, 0));
    _points.add(Offset(0, 0));
    _points.add(Offset(0, 0));
    _points.add(Offset(0, 0));
    ImageLoader.load("images/timg.jpg").then((image2) {
      setState(() {
        this.image = image2;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    if(first){
      first = false;
      _points[2] = Offset((width-cWidth)/2, (height-cHeight)/2);
    }
    return Container(
        child: Stack(
        children: [
        GestureDetector(
        onPanDown: onPanDown,
        onPanUpdate:onPanUpdate,
        onPanEnd: onPanEnd,
        ),
        CustomPaint(painter: new SignaturePainter(_points,width,height,cWidth,cHeight,image)),
        Container(
          child:Row(children: <Widget>[
            RaisedButton(
                child: Text("Cut"),
                onPressed: (){
                  //convert the clip square  to the clip image
                  double rate =this.image.width.toDouble()/width;
                  var source = Rect.fromLTWH(_points[2].dx *rate,(_points[2].dy-(height-_points[3].dy)/2) *rate,cWidth* rate,cHeight* rate);
                  var dest = Rect.fromLTWH(0,0,cWidth* rate,cHeight* rate);
                  PictureRecorder recorder =  PictureRecorder();
                  Canvas canvas2 = Canvas(recorder);
                  Paint paint2 = new Paint();
                  canvas2.drawImageRect(image, source, dest, paint2);
                  var image2 = recorder.endRecording().toImage(dest.width.toInt(), dest.height.toInt());
                  Navigator.push(context,new MaterialPageRoute(builder: (context) =>  ImageDetailPage(title: "image",image: image2)));

                }),

          ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
          ),
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.only(bottom: 10),
        ),
      ],
        )
    );
  }


  onPanDown(DragDownDetails details){
    RenderBox referenceBox = context.findRenderObject();
    Offset localPosition =
    referenceBox.globalToLocal(details.globalPosition);
    setState(() {
      if(_points.length<3){
        _points.add(localPosition);
        _points.add(localPosition);
        _points.add(Offset(0, 0));
        _points.add(Offset(0, 0));
      }
      else{
        _points[0]=localPosition;
        _points[1]=localPosition;
      }
      dHeight = cHeight;
      dWidth = cWidth;
      double radius = 20;
      if(hitPoint(Offset(_points[2].dx+cWidth, _points[2].dy+cHeight),radius , localPosition)){
        downPosition =DownPosition.RIGHT_DOWN;
        isDrag = false;
      }
      else if(hitPoint(Offset(_points[2].dx+cWidth, _points[2].dy),radius , localPosition)){
        downPosition =DownPosition.RIGHT_UP;
        isDrag = false;
      }
      else if(hitPoint(Offset(_points[2].dx, _points[2].dy+cHeight),radius , localPosition)){
        downPosition =DownPosition.LEFT_DOWN;
        isDrag = false;
      }
      else if(hitPoint(_points[2],radius , localPosition)){
        downPosition =DownPosition.LEFT_UP;
        isDrag = false;
      }

    });
  }
  onPanUpdate(DragUpdateDetails details) {
    RenderBox referenceBox = context.findRenderObject();
    Offset localPosition =
    referenceBox.globalToLocal(details.globalPosition);
    if(isDrag){
      setState(() {
        _points[1]=localPosition;
      });
    }
    else{
      setState(() {
        if(downPosition==DownPosition.RIGHT_DOWN){
          cWidth = dWidth+localPosition.dx - _points[1].dx;
          cHeight = dHeight +localPosition.dy-_points[1].dy;
        }
        else if(downPosition==DownPosition.LEFT_UP){
          cWidth = dWidth-(localPosition.dx - _points[1].dx);
          cHeight = dHeight-(localPosition.dy-_points[1].dy);
          _points[2]=localPosition;
        }
        else if(downPosition==DownPosition.RIGHT_UP){
          cWidth = dWidth+localPosition.dx - _points[1].dx;
          cHeight = dHeight-(localPosition.dy-_points[1].dy);
          _points[2]=Offset(_points[2].dx, localPosition.dy);
        }
        else if(downPosition==DownPosition.LEFT_DOWN){
          cWidth = dWidth-(localPosition.dx - _points[1].dx);
          cHeight = dHeight +localPosition.dy-_points[1].dy;
          _points[2]=Offset(localPosition.dx, _points[2].dy);
        }
        if(cWidth<20){
          cWidth=20;
        };
        if(cHeight<20){
          cHeight=20;
        }

      });
    }

  }
  onPanEnd(DragEndDetails details){
    setState(() {
      isDrag = true;
      double startX = _points[1].dx - _points[0].dx+_points[2].dx;
      double startY = _points[1].dy - _points[0].dy+_points[2].dy;
      if(startX<0)
        startX = 0;
      else if(startX+cWidth>width){
        startX = width-cWidth;
      }
      if(startY<0)
        startY=0;
      else if(startY + cHeight>height){
        startY = height-cHeight;
      }
      _points[0]=Offset(0, 0);
      _points[1]=Offset(0, 0);
      _points[2] = Offset(startX<0?0:startX, startY<0?0:startY);
    });
  }


  bool hitPoint(Offset offset,double radius,Offset down){
     if(down.dx>offset.dx-radius &&down.dx<offset.dx+radius&&down.dy>offset.dy-radius&&down.dy<offset.dy+radius){
       return true;
     }
     return false;
  }
}
