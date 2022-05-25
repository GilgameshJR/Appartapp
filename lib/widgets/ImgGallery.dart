import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker_gallery_camera/image_picker_gallery_camera.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImgGallery extends StatefulWidget {

  final Function(List<File>) callback; //will be called ONLY when new images are added or new images (ones which have been added during current "session", the ones which have to be uploaded) are removed
  List<GalleryImage>? existingImages=[];

  ImgGallery({Key? key, required this.callback, this.existingImages}) : super(key: key);

  @override
  _ImgGalleryState createState() => _ImgGalleryState(
    imagesToShow: (existingImages == null ? <GalleryImage>[] : existingImages as List<GalleryImage>),
  );
}

class GalleryImage {
  Image image;
  Function onDelete;

  GalleryImage(this.image, this.onDelete);
}

class _ImgGalleryState extends State<ImgGallery> {
  List<GalleryImage> imagesToShow=[];
  List<File> _toUpload=[];
  int currentOpenedPage=0;
  int currentSmallImage=0;

  _ImgGalleryState({Key? key, required this.imagesToShow});

  Future<void> getImage(ImgSource source) async {
    final PickedFile image = await ImagePickerGC.pickImage(
      context: context,
      source: source,
      cameraIcon: Icon(
        Icons.add,
        color: Colors.red,
      ),
    );

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      maxHeight: 1920,
      maxWidth: 1920,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),

        /// this settings is required for Web
        /*WebUiSettings(
          context: context,
          presentStyle: CropperPresentStyle.dialog,
          boundary: Boundary(
            width: 520,
            height: 520,
          ),
          viewPort: ViewPort(
              width: 480,
              height: 480,
              type: 'circle'
          ),
          enableExif: true,
          enableZoom: true,
          showZoomer: true,
        )*/
      ],
    );

    if (croppedFile != null) {
      croppedFile.readAsBytes().then((byteStream) {
        File file=File(croppedFile.path);
        _toUpload.add(file);
        widget.callback(_toUpload);
        setState(() {
          imagesToShow.add(GalleryImage(Image.file(file), () {
            _toUpload.remove(file);
          }));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> imageSliders = [];
    imagesToShow.forEach((element) {
      imageSliders.add(Container(
        //child: Image.file(File(croppedFile.path)),
        child: element.image,
        //child: Image.memory(croppedFile.readAsBytesSync()),
        //constraints: const BoxConstraints(maxWidth: 200),
      ));
    });

    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (imageSliders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Container(
                    //color: Colors.amber,
                      child: GestureDetector(
                        onTap: () {
                          currentOpenedPage=currentSmallImage;

                          Navigator.of(context).push(PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => DismissiblePage(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CarouselSlider(
                                        options: CarouselOptions(
                                          onPageChanged: (pageN, CarouselPageChangedReason reason) {
                                            currentOpenedPage=pageN;
                                          },
                                          aspectRatio: 1,
                                          enableInfiniteScroll: false,
                                          initialPage: currentSmallImage,
                                          viewportFraction: 1,
                                        ),
                                        items: imageSliders),
                                    Positioned(
                                        bottom: 30,
                                        right: 30,
                                        height: 70,
                                        width: 70,
                                        child:
                                        FloatingActionButton(
                                          child: const Icon(Icons.remove),
                                          backgroundColor: Colors.brown,
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              imagesToShow[currentOpenedPage].onDelete();
                                              imagesToShow.removeAt(currentOpenedPage);
                                            });
                                          },
                                        )),
                                  ],
                                ),
                              ),
                              onDismissed: () => Navigator.of(context).pop(),
                              startingOpacity: 0.8,
                              dragSensitivity: 1,
                            ),
                          ));
                        },
                        child: CarouselSlider(
                          options: CarouselOptions(
                            onPageChanged: (pageN, CarouselPageChangedReason reason) {
                              currentSmallImage=pageN;
                            },
                            aspectRatio: 2,
                            enableInfiniteScroll: false,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 2),
                            viewportFraction: 0.8,
                          ),
                          items: imageSliders,
                        ),
                      )),
                )
              else
                Container(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton(
                  child: const Icon(Icons.add_a_photo),
                  backgroundColor: Colors.brown,
                  onPressed: () => getImage(ImgSource.Both),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}