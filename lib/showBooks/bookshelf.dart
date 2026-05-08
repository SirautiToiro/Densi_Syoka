import 'package:flutter/material.dart';
import 'package:barcode_reader/sukyan/bookdata.dart';
import 'package:barcode_reader/data/bookdatabase.dart';
import 'package:barcode_reader/showBooks/bookdetail.dart';
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:io';

class BookShelfWidget extends StatefulWidget {
  const BookShelfWidget({super.key});

  @override
  State<BookShelfWidget> createState() => _BookShelfWidgetState();
}

class _BookShelfWidgetState extends State<BookShelfWidget> {
  //検索に使用するデータ
  String _searchString = "";
  bool _isSearchComment = true;
  bool _isSearchBookdata = true;
  final List<bool> _toggleSelected = [true, false];
  bool _isAscending = false;

  //10個ずつの本のデータを表示する。
  //nページ目にいるとき、_showOffset = n-1
  int _showPage = 0;
  final int _showMax = 10;

  //表示している本のリストを一新するフラグ
  bool _listRefleshFlag = false;

  //表示している本のデータ
  List<Map>? _bookDataMap;

  void _goBookDetail(BuildContext context, int id) async {
    var map = (await Bookdatabase.instance.getItems(id))[0];
    BookData bookData = BookData(
      map['title'],
      map['author'],
      map['imagePath'],
      map['isbnCode'],
      false,
      map['comment'],
      map['id'],
      map['created_at'],
      map['score'],
    );

    if (!context.mounted) return;

    //詳細画面に画面遷移
    //これは待ち続けていて、戻った時にtrueなら再描画する。
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookDetailWidget(bookData: bookData),
      ),
    );

    if (result) {
      // [*5]
      _listRefleshFlag = true;
      setState(() {});
      // notifyListeners();
    }
  }

  Future<List<Map>> getData(
    String searchString,
    bool isSearchComment,
    bool isSearchBookdata,
    List<bool> sortType,
    bool isAscending,
  ) async {
    if (_listRefleshFlag || _bookDataMap == null) {
      
      //リストを更新する必要があるなら、データを取りに行く
      var results = await Bookdatabase.instance.searchItems(
        searchString,
        isSearchComment,
        isSearchBookdata,
        sortType,
        isAscending,
      );
      _bookDataMap = results;

      _listRefleshFlag = false; //次は更新しない
      return results;
    } else {
      
      //リストを更新する必要がないなら、すでに取得したデータを使用する
      return _bookDataMap!;
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF66FF99),
        title: 
        Container(
          alignment: Alignment.center,
          child: const Text('読み込んだ本の一覧'),
        )
      ),
      body: FutureBuilder<List<Map>>(
        //本一覧のデータを取得
        future: getData(
          _searchString,
          _isSearchComment,
          _isSearchBookdata,
          _toggleSelected,
          _isAscending,
        ),
        builder: (BuildContext context, AsyncSnapshot<List<Map>> snapshot) {
          List<Widget> children = <Widget>[];
          if (snapshot.hasData) {
            //データがあったなら
            if (snapshot.data!.isEmpty) {
              //データの長さが0なら
              children.add(
                Card(
                  color: const Color(0xFFBBFFDD),
                  elevation: 5,
                  margin: const EdgeInsets.all(9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(Icons.image_not_supported),
                        title: Text(
                          '書籍が見つかりませんでした',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '検索条件を変更するか、書籍を追加してください',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              //取得したリストの部分のみ表示
              int showStart = _showPage * _showMax;
              int showEnd = _showPage * _showMax+_showMax;
              //リストの長さに合わせる
              if(showEnd>snapshot.data!.length)showEnd = snapshot.data!.length;
              
              for (final map in snapshot.data!.sublist(showStart,showEnd)) {
                DateTime dataCreatedTime = DateTime.fromMillisecondsSinceEpoch(
                  map['created_at'],
                );

                //コメントは最初の3行のみを表示する
                String dataComment = map['comment'];
                List<String> splittedComment = LineSplitter().convert(
                  dataComment,
                );
                String viewComment = "";
                for (int i = 0; i < 3 && i < splittedComment.length; i++) {
                  if (i != 0) viewComment += "\n";
                  viewComment += splittedComment[i];
                }

                children.add(
                  Card(
                    color: const Color(0xFFBBFFDD),
                    elevation: 5,
                    margin: const EdgeInsets.all(9),
                    child: TextButton(
                      onPressed: () {
                        //詳細画面に画面遷移
                        //遷移後に戻ってきたときには再描画をする可能性あり
                        _goBookDetail(context, map['id']);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: getImage(map['imagePath']),
                            title: Text(
                              map['title'],
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${map['author']}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),

                          Row(
                            children: [
                              Text(
                                "${dataCreatedTime.year}年${dataCreatedTime.month}月${dataCreatedTime.day}日",
                                style: TextStyle(fontSize: 22),
                                textAlign: TextAlign.left,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: RatingBar.builder(
                                  //星の表示
                                  itemBuilder:
                                      (context, index) =>
                                          const Icon(Icons.star),
                                  onRatingUpdate: (rating) {
                                    //評価が更新されることはない
                                  },
                                  initialRating: map['score'].toDouble(),
                                  ignoreGestures: true, //操作を受け付けない
                                ),
                              ),
                            ],
                          ),

                          Text(
                            viewComment,
                            style: TextStyle(fontSize: 22),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            }
          } else if (snapshot.hasError) {
            // エラーが発生した場合の処理
            children = <Widget>[
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              ),
            ];
          } else {
            // 値が存在しない場合の処理
            children = const <Widget>[
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Awaiting result...'),
              ),
            ];
          }
          return Column(
            children: [
              //ページ切り替え
              Container(
                color: const Color.fromARGB(255, 231, 234, 219),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          _showPage <= 0
                              ? null //最初のページにいるなら戻るボタンは表示しない
                              : () {
                                setState(() {
                                  //ページを戻す
                                  _showPage -= 1;
                                });
                              },
                      icon: Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 10),
                    Text("ページ切り替え"),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed:
                          //次に表示するページがあるなら
                          ((_bookDataMap?.length) ?? -1) <=
                                  (_showPage + 1) * _showMax
                              ? null
                              : () {
                                setState(() {
                                  //ページを進める
                                  _showPage += 1;
                                });
                              },
                      icon: Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),

              //書籍情報リスト
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),

              //検索バー
              Container(
                color: const Color.fromARGB(255, 231, 234, 219),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          child: Icon(Icons.search, size: 35),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 200.0, // ここで幅を設定
                          child: TextField(
                            maxLines: 1,

                            onChanged: (text) {
                              _searchString = text;
                            },
                          ),
                        ),

                        Row(
                          children: [
                            Checkbox(
                              value: _isSearchBookdata,
                              onChanged: (value) {
                                setState(() {
                                  _isSearchBookdata =
                                      value!; // チェックボックスに渡す値を更新する
                                });
                              },
                            ),
                            Text("書籍情報検索", style: TextStyle(fontSize: 32)),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _isSearchComment,
                              onChanged: (value) {
                                setState(() {
                                  _isSearchComment =
                                      value!; // チェックボックスに渡す値を更新する
                                });
                              },
                            ),
                            Text("コメント検索", style: TextStyle(fontSize: 32)),
                          ],
                        ),
                      ],
                    ),
                    //日本語でのソートがフリガナがないとできないので、ソートはなし。
                    //登録日と評価でのソートのみ行う
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                            ),
                            child: Icon(Icons.sort, size: 35),
                          ),
                          const SizedBox(width: 10),
                          ToggleButtons(
                            color: Colors.red,
                            fillColor: Colors.red[300],
                            borderColor: Colors.red[100],
                            splashColor: Colors.red[300],
                            selectedBorderColor: Colors.red[800],
                            selectedColor: Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            isSelected: _toggleSelected,
                            children: const [
                              Text("登録日", style: TextStyle(fontSize: 28)),
                              Text("評価", style: TextStyle(fontSize: 28)),
                            ],
                            onPressed: (int index) {
                              setState(() {
                                for (
                                  int i = 0;
                                  i < _toggleSelected.length;
                                  i++
                                ) {
                                  if (i == index) {
                                    _toggleSelected[i] = true;
                                  } else {
                                    _toggleSelected[i] = false;
                                  }
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              //適用ボタンを押すと再描画する
                              setState(() {
                                //昇順、降順を反転
                                setState(() {
                                  _isAscending = !_isAscending;
                                });
                              });
                            },
                            child: Row(
                              children: [
                                _isAscending
                                    ? Icon(Icons.arrow_upward, size: 35)
                                    : Icon(Icons.arrow_downward, size: 35),

                                Text(
                                  _isAscending ? "昇順" : "降順",
                                  style: TextStyle(fontSize: 32),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                        onPressed: () {
                          //適用ボタンを押すと再描画する
                          setState(() {
                            //ページを0に
                            _showPage = 0;
                            //リストを再更新する
                            _listRefleshFlag = true;
                          });
                        },
                        child: Text("適用", style: TextStyle(fontSize: 32)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
