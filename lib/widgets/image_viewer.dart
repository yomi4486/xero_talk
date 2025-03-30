import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerPage extends StatefulWidget {
  ImageViewerPage(this.content, this.imageControler);

  final Uint8List content;
  final Function(Uint8List, bool) imageControler;

  @override
  _ImageViewerPageState createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  Offset beginningDragPosition = Offset.zero;
  Offset currentDragPosition = Offset.zero;
  PhotoViewScaleState scaleState = PhotoViewScaleState.initial;
  int photoViewAnimationDurationMilliSec = 0;
  double barsOpacity = 1.0;

  double get photoViewScale {
    return max(1.0 - currentDragPosition.distance * 0.001, 0.8);
  }

  double get photoViewOpacity {
    return max(1.0 - currentDragPosition.distance * 0.005, 0.1);
  }

  Matrix4 get photoViewTransform {
    final translationTransform = Matrix4.translationValues(
      currentDragPosition.dx,
      currentDragPosition.dy,
      0.0,
    );

    final scaleTransform = Matrix4.diagonal3Values(
      photoViewScale,
      photoViewScale,
      1.0,
    );

    return translationTransform * scaleTransform;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildImage(context),
          _buildTopBar(context),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onTap: onTapPhotoView,
      onVerticalDragStart: scaleState == PhotoViewScaleState.initial
          ? onVerticalDragStart
          : null,
      onVerticalDragUpdate: scaleState == PhotoViewScaleState.initial
          ? onVerticalDragUpdate
          : null,
      onVerticalDragEnd:
          scaleState == PhotoViewScaleState.initial ? onVerticalDragEnd : null,
      child: Container(
        color: Colors.black.withOpacity(photoViewOpacity),
        child: AnimatedContainer(
          duration: Duration(milliseconds: photoViewAnimationDurationMilliSec),
          transform: photoViewTransform,
          child: PhotoView(
            backgroundDecoration: BoxDecoration(color: Colors.transparent),
            imageProvider: MemoryImage(widget.content),
            minScale: PhotoViewComputedScale.contained,
            scaleStateChangedCallback: (state) {
              setState(() {
                scaleState = state;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topBarHeight = 64.0;
    return AnimatedOpacity(
      duration: Duration(milliseconds: 75),
      opacity: barsOpacity,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        height: topBarHeight,
        child: Column(
          children: [
            Container(height: statusBarHeight),
            SizedBox(
              height: topBarHeight - statusBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(width: 8.0),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30.0,
                    ),
                    onPressed: () {
                      widget.imageControler(widget.content, false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onTapPhotoView() {
    setState(() {
      barsOpacity = (barsOpacity <= 0.0) ? 1.0 : 0.0;
    });
  }

  void onVerticalDragStart(DragStartDetails details) {
    setState(() {
      barsOpacity = 0.0;
      photoViewAnimationDurationMilliSec = 0;
    });
    beginningDragPosition = details.globalPosition;
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      barsOpacity = (currentDragPosition.distance < 20.0) ? 1.0 : 0.0;
      currentDragPosition = Offset(
        details.globalPosition.dx - beginningDragPosition.dx,
        details.globalPosition.dy - beginningDragPosition.dy,
      );
    });
  }

  void onVerticalDragEnd(DragEndDetails details) {
    if (currentDragPosition.distance < 100.0) {
      setState(() {
        photoViewAnimationDurationMilliSec = 200;
        currentDragPosition = Offset.zero;
        barsOpacity = 1.0;
      });
    } else {
      widget.imageControler(widget.content, false);
    }
  }
}
