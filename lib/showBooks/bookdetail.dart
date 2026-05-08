import 'package:flutter/material.dart';
import 'package:barcode_reader/sukyan/bookdata.dart';
import 'package:barcode_reader/data/bookdatabase.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:io';

class BookDetailWidget extends StatefulWidget {
  final BookData bookData;

  const BookDetailWidget({super.key, required this.bookData});

  @override
  State<BookDetailWidget> createState() => _BookDetailWidgetState();
}

class _BookDetailWidgetState extends State<BookDetailWidget> {
  //本に対して付けたコメント
  String _comment = "";
  int _rating = 3;

  //画像のパスから画像を取得する。存在しないならアイコンを返す.
  Widget getImage(String? imagePath) {
    if (imagePath == null || File(imagePath).existsSync()) {
      File imageFile = File(imagePath!);

      return Image.file(imageFile);
    } else {
      return Icon(Icons.image_not_supported);
    }
  }

  @override
  Widget build(BuildContext context) {
    _comment = widget.bookData.comment ?? "";
    _rating = widget.bookData.score ?? 3;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF66FF99),
        title: Container(alignment: Alignment.center, child: Text('書籍詳細')),
      ),
      body: SingleChildScrollView(
        child: Card(
          color: const Color(0xFFBBFFDD),
          elevation: 5,
          margin: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    //画像
                    padding: const EdgeInsets.only(top: 16),
                    child: getImage(widget.bookData.imageFileName),
                  ),
                  Expanded(
                    child: Padding(
                      //タイトル、作者
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.bookData.title}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                            softWrap: true,
                            overflow: TextOverflow.clip,
                          ),
                          Text(
                            '${widget.bookData.author}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.left,
                            softWrap: true,
                            overflow: TextOverflow.clip,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              //コメント
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  controller: TextEditingController(text: _comment),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(hintText: '本へのコメント'),
                  onChanged: (text) {
                    _comment = text;
                  },
                ),
              ),
              //評価
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: RatingBar.builder(
                  itemBuilder: (context, index) => const Icon(Icons.star),
                  onRatingUpdate: (rating) {
                    //評価が更新された
                    _rating = rating.toInt();
                  },
                  initialRating: _rating.toDouble(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      //コメントと評価のみ更新
                      Map<String, dynamic> map = {
                        'id': widget.bookData.id,
                        'title': widget.bookData.title,
                        'author': widget.bookData.author,
                        'imagePath': widget.bookData.imageFileName,
                        'isbnCode': widget.bookData.isbnCode,
                        'comment': _comment,
                        'score': _rating,
                        'created_at': widget.bookData.createdTime,
                      };
                      Bookdatabase.instance.updateItem(map);
                      //前の画面(一覧画面)に画面遷移
                      //再描画のための引数を入れている
                      Navigator.of(context).pop(true);
                    },
                    child: Text("適用"),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      //警告を表示
                      //削除したならTrueを返す
                      bool? res = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("削除"),
                            content: Text("本当に削除しますか？"),
                            actions: [
                              TextButton(
                                child: Text("Cancel"),
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                              ),
                              TextButton(
                                child: Text("OK"),
                                onPressed: () async {
                                  if (widget.bookData.id == null) return;
                                  await Bookdatabase.instance.deleteItem(
                                    widget.bookData.id!,
                                  );

                                  if (!context.mounted) return;
                                  //削除するためtrueを返し、Dialogを閉じる
                                  Navigator.pop(context, true);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (res!) {
                        //削除したなら
                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: Text("削除"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
