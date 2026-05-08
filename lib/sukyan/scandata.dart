import 'package:barcode_reader/sukyan/bookdata.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_reader/data/bookdatabase.dart';
import 'package:barcode_reader/showBooks/bookshelf.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ScanDataWidget extends StatefulWidget {
  final BarcodeCapture? scandata; // スキャナーのページから渡されたデータ
  const ScanDataWidget({super.key, this.scandata});

  @override
  State<ScanDataWidget> createState() => _ScanDataWidgetState();
}

class _ScanDataWidgetState extends State<ScanDataWidget> {
  final String BOOK_API_PREFIX =
      'https://www.googleapis.com/books/v1/volumes?country=JP&q=isbn:';

  //本に対して付けたコメント
  String _comment = "";

  //本に対して付けた評価
  int _rating = 3;

  //scanDataのcodeTypeは必ずISBNである。それをAPIに送り、書籍情報を取得する
  Future<BookData> analyzeISBN(BarcodeCapture scanData) async {
    // コードから読み取った文字列
    String codeValue = scanData.barcodes.first.rawValue ?? 'null';

    final String message = BOOK_API_PREFIX + codeValue.toString();

    //API通信
    final response = await http.get(Uri.parse(message));
    return analyzeResponse(response, codeValue);
  }

  Future<BookData> analyzeResponse(
    http.Response response,
    String barcode,
  ) async {
    Map<String, dynamic> map = json.decode(response.body);

    //String title = map.toString();
    String title = map['items'][0]['volumeInfo']['title'] ?? "タイトルが読み込めません";

    String author =
        map['items'][0]['volumeInfo']['authors']?.join(',') ?? "著者が読み込めません";

    String imagePath =
        map['items'][0]['volumeInfo']['imageLinks']?['smallThumbnail'] ?? "";
    //読み込めない場合は空文字列

    //画像を一時ファイルに保存する。そのパスを取得
    final String tempPath = (await getTemporaryDirectory()).path;

    //ファイルのパス
    String filePath = '$tempPath/$barcode.png';

    ///*
    //取得したパスにバーコードと同じファイル名で新しいファイルを作成
    final File file = File(filePath);

    if (File(filePath).existsSync()) {
      //すでに何かの原因でそれを読み取っている
    } else {
      //読み取っていないので読み取る
      if (imagePath == "") {
        //Httpレスポンス内に画像データが含まれていない
        //返答も空文字列
        filePath = "";
      } else {
        //http.getメソッドを呼び出し、それにimageUrlを変換したUriを渡して応答を取得
        http.Response imageResponse = await http.get(Uri.parse(imagePath));

        //fileへhttp.getで受信したbodyBytesを書き込み
        await file.writeAsBytes(imageResponse.bodyBytes);
      }
    }
    //*/

    bool alreadyExistFlag = false;
    //既にデータが存在しているかを検索
    if (await Bookdatabase.instance.isExistItem(barcode)) {
      //既に存在している
      alreadyExistFlag = true;
    } else {}

    return BookData(title, author, filePath, barcode, alreadyExistFlag);
    //return BookData(title, author, "testPath", barcode);
  }

  //画像のパスから画像を取得する。存在しないならアイコンを返す.
  (Widget, File?) getImage(String? imagePath) {
    //debugPrint(imagePath);
    if (imagePath != null && imagePath != "" && File(imagePath).existsSync()) {
      //imagePathが存在する
      File imageFile = File(imagePath);

      return (Image.file(imageFile), imageFile);
    } else {
      return (Icon(Icons.image_not_supported), null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // コードから読み取った文字列
    String codeValue = widget.scandata?.barcodes.first.rawValue ?? 'null';
    // コードのタイプを示すオブジェクト
    BarcodeType? codeType = widget.scandata?.barcodes.first.type;
    // コードのタイプを文字列にする
    String cardTitle = "[${'$codeType'.split('.').last}]";
    // 読み取った内容を表示するウィジェット
    dynamic cardSubtitle = Text(
      codeValue,
      style: const TextStyle(fontSize: 23, color: Color(0xFF553311)),
    );

    if (widget.scandata == null) {
      //読み込み失敗
      cardTitle = '読み込み失敗';
    } else if (codeType == BarcodeType.url) {
      // タイプがURLである場合
      cardTitle = 'どこかのURL';
      cardSubtitle = InkWell(
        child: Text(
          codeValue,
          style: const TextStyle(
            fontSize: 23,
            color: Color(0xFF1133DD), // 藍色の文字
            decoration: TextDecoration.underline, // 下線
            decorationColor: Color(0xFF1133DD), // 下線の色
          ),
        ),
        // 押したらウェブサイトに入る
        onTap: () async {
          if (await canLaunchUrlString(codeValue)) {
            await launchUrlString(codeValue);
          }
        },
      );
    } else if (codeType == BarcodeType.isbn) {
      //読み込んだものが書籍のISBN
      final Future<BookData> bookData = analyzeISBN(widget.scandata!);

      cardTitle = '読み取り結果';
      cardSubtitle = FutureBuilder<BookData>(
        future: bookData, // Future<T> 型を返す非同期処理
        builder: (BuildContext context, AsyncSnapshot<BookData> snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            Widget imageWidget;
            File? imageFile;
            (imageWidget, imageFile) = getImage(snapshot.data!.imageFileName);

            // 値が存在する場合の処理
            children = <Widget>[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 60,
              ),
              //書籍説明
              Row(
                children: [
                  Padding(
                    //画像
                    padding: const EdgeInsets.only(top: 16),
                    child: imageWidget,
                  ),
                  Expanded(
                    child: Padding(
                      //タイトル、作者
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${snapshot.data!.title}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                            softWrap: true,
                            overflow: TextOverflow.clip,
                          ),
                          Text(
                            '${snapshot.data!.author}',
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
            ];

            if (snapshot.data!.alreadyExistFlag) {
              //既に存在しているなら登録できない
              children.add(Text("すでに書籍が登録されています"));
              children.add(
                OutlinedButton(
                  onPressed: () {
                    //(画面を一歩戻る処理)
                    //同時に戻るボタンで戻るときに使うための戻りデータを
                    //ホーム画面にする
                    Navigator.of(context).pop();
                  },
                  child: Text("キャンセル"),
                ),
              );
            } else {
              //登録UIを表示
              //コメント
              children.add(
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextField(
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: InputDecoration(hintText: '本へのコメント'),
                    onChanged: (text) {
                      _comment = text;
                    },
                  ),
                ),
              );
              //評価
              children.add(
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
              );
              //決定ボタン
              children.add(
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      //登録ボタン
                      OutlinedButton(
                        onPressed: () async {
                          //ライブラリディレクトリを取得
                          var directoryPath =
                              (await getApplicationSupportDirectory()).path;
                          //実際の保存場所(一時的でない)に画像を保存するパス
                          String fileSavedPath =
                              "$directoryPath/${snapshot.data!.isbnCode}.png";

                          //画像ファイルをコピー
                          //画像が既に存在するかを確認
                          if (File(fileSavedPath).existsSync()) {
                            //すでに何かの原因でそれを記録している
                          } else {
                            //記録していないのでコピー
                            imageFile?.copy(fileSavedPath);
                          }

                          Map<String, dynamic> map = {
                            'title': snapshot.data!.title,
                            'author': snapshot.data!.author,
                            'imagePath': fileSavedPath,
                            'isbnCode': snapshot.data!.isbnCode,
                            'comment': _comment,
                            'score': _rating,
                            'created_at': DateTime.now().millisecondsSinceEpoch,
                          };

                          Bookdatabase.instance.insertItem(map);
                          //書庫画面に画面遷移
                          //同時に戻るボタンで戻るときに使うための戻りデータを
                          //ホーム画面にする
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => BookShelfWidget(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                        child: Text("登録"),
                      ),

                      //キャンセルボタン
                      OutlinedButton(
                        onPressed: () {
                          //読み取り画面に画面遷移(画面を一歩戻る処理)
                          //同時に戻るボタンで戻るときに使うための戻りデータを
                          //ホーム画面にする
                          Navigator.of(context).pop();
                        },
                        child: Text("キャンセル"),
                      ),
                    ],
                  ),
                ),
              );
            }
          } else if (snapshot.hasError) {
            // エラーが発生した場合の処理
            children = <Widget>[
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                //child: Text('Error: ${snapshot.error}'),
                child: Text('読み取り失敗。\nバーコードが適切に読み取られなかったか、\nネットワークに接続されていません。'),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          );
        },
      );
      //final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));
    } else {
      //特に関係のないバーコード
      cardTitle = "書籍のISBNコードではありません。";
      cardSubtitle = Text(
        codeValue,
        style: const TextStyle(fontSize: 23, color: Color(0xFF553311)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF66FF99),
        title: Container(
          alignment: Alignment.center,
          child: const Text('スキャンの結果'),
        ),
      ),
      body: SingleChildScrollView(
        child: Card(
          color: const Color(0xFFBBFFDD),
          elevation: 5,
          margin: const EdgeInsets.all(9),
          child: ListTile(
            title: Text(
              cardTitle,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            subtitle: cardSubtitle,
          ),
        ),
      ),

      //FutureBuilder処理例
      /*
      FutureBuilder<String>(
        future: _calculation, // Future<T> 型を返す非同期処理
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            // 値が存在する場合の処理
            children = <Widget>[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Result: ${snapshot.data}'),
              ),
            ];
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          );
        },
      ),*/
    );
  }
}
