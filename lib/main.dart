import 'package:flutter/material.dart';
import 'package:barcode_reader/sukyan/scanner.dart';
import 'package:barcode_reader/data/bookdatabase.dart';
import 'package:barcode_reader/showBooks/bookshelf.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

//バーコードスキャナーのコードはこのサイトから
//https://qiita.com/phyblas/items/3b0be832cc3f6792e5e0

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '電子書架',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '電子書架'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    //androidの時に表示するメイン画面。データベースを初期化してから表示
    final FutureBuilder<bool> androidMainPage = FutureBuilder<bool>(
      future: Bookdatabase.instance.initBookDatabase(), // Future<T> 型を返す非同期処理
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        List<Widget> children;
        if (snapshot.hasData) {
          // 値が存在する場合の処理

          children = <Widget>[
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 42),
                  child: Text(
                    '電子書架',
                    style: TextStyle(
                      fontSize: 108,
                      color: Color.fromARGB(255, 170, 68, 151),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Image.asset('assets/MultiTasker.png', scale: 1.6),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          // 押したらスキャンの画面に入るボタン
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ScannerWidget(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 20, // ボタンが画面から浮かぶ高さ（影で現す）
                            fixedSize: const Size.fromHeight(300), // ボタンの大きさ
                            backgroundColor: const Color(
                              0xFFAADDCC,
                            ), // ボタンの背景の色
                            side: const BorderSide(
                              color: Color(0xFF44AA66),
                              width: 6,
                            ), // ボタンの枠線
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_sharp, // QRスキャンのアイコン
                                size: 120,
                              ),
                              Text('スキャンを始める', style: TextStyle(fontSize: 36)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          // 押したら書架閲覧画面に移動するボタン
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BookShelfWidget(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 20, // ボタンが画面から浮かぶ高さ（影で現す）
                            fixedSize: const Size.fromHeight(300), // ボタンの大きさ
                            backgroundColor: const Color.fromARGB(
                              255,
                              170,
                              199,
                              221,
                            ), // ボタンの背景の色
                            side: const BorderSide(
                              color: Color(0xFF44AA66),
                              width: 6,
                            ), // ボタンの枠線
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book, // 本のアイコン
                                size: 120,
                              ),
                              Text('書架を閲覧', style: TextStyle(fontSize: 36)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
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
            SizedBox(width: 60, height: 60, child: CircularProgressIndicator()),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Initializing Database...'),
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
    /*
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '電子書架',
          style: TextStyle(
            fontSize: 82,
            color: Color.fromARGB(255, 170, 68, 151),
          ),
        ),
        ElevatedButton(
          // 押したらスキャンの画面に入るボタン
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ScannerWidget()),
            );
          },
          style: ElevatedButton.styleFrom(
            elevation: 20, // ボタンが画面から浮かぶ高さ（影で現す）
            fixedSize: const Size.fromHeight(300), // ボタンの大きさ
            backgroundColor: const Color(0xFFAADDCC), // ボタンの背景の色
            side: const BorderSide(
              color: Color(0xFF44AA66),
              width: 6,
            ), // ボタンの枠線
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner_sharp, // QRスキャンのアイコン
                size: 120,
              ),
              Text('スキャンを始める', style: TextStyle(fontSize: 36)),
            ],
          ),
        ),
        ElevatedButton(
          // 押したら書架閲覧画面に移動するボタン
          onPressed: () {
            //TODO
          },
          style: ElevatedButton.styleFrom(
            elevation: 20, // ボタンが画面から浮かぶ高さ（影で現す）
            fixedSize: const Size.fromHeight(300), // ボタンの大きさ
            backgroundColor: const Color.fromARGB(
              255,
              170,
              199,
              221,
            ), // ボタンの背景の色
            side: const BorderSide(
              color: Color(0xFF44AA66),
              width: 6,
            ), // ボタンの枠線
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book, // 本のアイコン
                size: 120,
              ),
              Text('書架を閲覧', style: TextStyle(fontSize: 36)),
            ],
          ),
        ),
      ],
    );
    */

    final Text otherOSErrorText = Text("このプログラムはAndroidでのみ動作します");

    Widget showByPlatform() {
      try {
        return Platform.isAndroid ? androidMainPage : otherOSErrorText;
      } catch (e) {
        return otherOSErrorText;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(child: showByPlatform()),
    );
  }
}
