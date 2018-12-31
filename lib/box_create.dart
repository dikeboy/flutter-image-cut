import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:transparent_image/transparent_image.dart';
import 'package:image_cut/fade_in_cache.dart' as fcache;
class MyBoxPage extends StatefulWidget {
  MyBoxPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyBoxPageState createState() => _MyBoxPageState();
}

class _MyBoxPageState extends State<MyBoxPage> {
List widgets =[];
bool  load = false;
double width;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
  }
  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    return Container(
        child: getListView(),
    );
  }

  getListView(){
    if(!load){
      return Container(
         alignment: Alignment.center,
        child: CircularProgressIndicator(
          strokeWidth: 1.0,
        ),
        color: Colors.white,
      );
    }else{
    return   Container(
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return getChild(index);
          },
          itemCount: widgets.length,
        ),
      color: Colors.white,
      );
    }

  }
 getChild(int position){
    print("child ${position}");
    var d = widgets[position];
    return Container(
      child:
      fcache.FadeInImage.memoryNetwork(
          image: d["url"],
          sdcache: true,
          placeholder: kTransparentImage,
          width: width,
          height: d["height"]* width/d["width"],
          ),
    );
//    Image.network(src)
 }
  loadData() async {
    String dataURL = "https://sg.mangatoon.mobi/api/cartoons/pictures?sign=13d6205ff123cd8ffacc9c5e5f4f0b5a&id=3905&_=1546155223&_language=en&_udid=dcd28ecf49b45486cf6b2b743371d500&callback=jsonp_2";
    http.Response response = await http.get(dataURL);
    setState(() {
      String result = response.body;
      result = result.substring(result.indexOf("(")+1,result.length-1);
      load = true;
      widgets = json.decode(result)["data"];
      widgets.forEach((d){
        String url = d["url"];
        d["url"]=url.substring(0,url.indexOf("encrypted"))+"watermark/"+ url.substring(url.lastIndexOf("/"),url.length-4)+"jpg";
      });
      for(int i=0;i<100;i++){
        widgets.add(widgets[i%10]);
      }
      print(widgets);
    });
  }
}
