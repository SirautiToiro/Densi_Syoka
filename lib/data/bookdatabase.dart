import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Bookdatabase {
  static Bookdatabase? _instance;
  Bookdatabase._();
  static Bookdatabase get instance => _instance ??= Bookdatabase._();

  // getterアクセスを利用するので、newでインスタンスを生成しませんが、バカ除け程度にfactoryを置いています
  factory Bookdatabase() => instance;

  static Database? _database;

  // データベースのインスタンスを取得（存在しない場合は初期化）
  // ※database: getter定義プロパティ
  //   get: これを定義する為のgetterメソッド
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  //最初に呼ばれる初期化
  Future<bool> initBookDatabase() async {
    _database = await _initDatabase();
    return true;
  }

  Future<Database> _initDatabase() async {
    //データベースを保存するパスを指定(これは間違えている)
    /*
    var databasesPathFail = await getApplicationSupportDirectory();
    String pathFail = '$databasesPathFail/bookDatabase.db';
    debugPrint("不要データベース削除");
    await deleteDatabase(pathFail);
    */

    //データベースを保存するパスを指定
    var databasesPath = (await getApplicationSupportDirectory()).path;
    String path = '$databasesPath/bookDatabase.db';

    //それまでに存在していたデータベースを削除(データベース構造が変わったときに実行)
    //await deleteDatabase(path);

    //データベースを作成。pathの保存場所に作成.
    //bookDataというテーブル名に、読み込んだ本のデータを格納。
    Database db = await openDatabase(
      path,
      version: 1, // onCreateを指定する場合はバージョンを指定する
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS bookData ('
          '  id INTEGER PRIMARY KEY AUTOINCREMENT,'
          '  title TEXT,'
          '  author TEXT,'
          '  imagePath TEXT,'
          '  isbnCode TEXT,'
          '  comment TEXT,'
          '  score INTEGER,'
          '  created_at INTEGER'
          ')',
        );
      },
    );

    /*
    //テスト.履歴をすべて削除
    await db.delete('bookData');
    
    //テスト挿入
    await db.insert(
      'bookData', // テーブル名
      {
        'title': 'Rainy Night', // カラム名: 値
        'author': 'PinkMan', // カラム名: 値
        'imagePath': 'testImagePath', // カラム名: 値
        'isbnCode': '0000000000000',
        'comment': 'testComment1\nCat and Whisper',
        'score': '3',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );

    //テスト挿入
    await db.insert(
      'bookData', // テーブル名
      {
        'title': '驚くよりも素早く', // カラム名: 値
        'author': '三谷 平八郎', // カラム名: 値
        'imagePath': 'testImagePath2', // カラム名: 値
        'isbnCode': '0000000000000',
        'comment': 'testComment2\n虫と騒音',
        'score': '1',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
    //テスト挿入
    await db.insert(
      'bookData', // テーブル名
      {
        'title': 'A Plane Plane', // カラム名: 値
        'author': 'SeeingMan', // カラム名: 値
        'imagePath': 'testImagePath2', // カラム名: 値
        'isbnCode': '0000000000000',
        'comment': 'testComment2\nKing and Clown',
        'score': '2',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
    //テスト挿入
    await db.insert(
      'bookData', // テーブル名
      {
        'title': 'SUPERDRINKER', // カラム名: 値
        'author': 'Queen John', // カラム名: 値
        'imagePath': 'testImagePath2', // カラム名: 値
        'isbnCode': '0000000000000',
        'comment': 'testComment2\nMix Juice for YOU',
        'score': '4',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
    //テスト挿入
    await db.insert(
      'bookData', // テーブル名
      {
        'title': '見上げた休暇', // カラム名: 値
        'author': '塩谷 静', // カラム名: 値
        'imagePath': 'testImagePath2', // カラム名: 値
        'isbnCode': '0000000000000',
        'comment': 'testComment2\n悲しい並木道',
        'score': '5',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
    //テスト挿入
    await db.insert(
      'bookData', // テーブル名
      {
        'title': '明日には八月', // カラム名: 値
        'author': '渡辺 博', // カラム名: 値
        'imagePath': 'testImagePath2', // カラム名: 値
        'isbnCode': '0000000000000',
        'comment': 'testComment2\n虫の多い並木道',
        'score': '2',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );

    String longtext =
        '寿限無寿限無五劫ごこうのすりきれ海砂利水魚の水行末・雲来末・風来末食う寝るところに住むところやぶらこうじのぶらこうじパイポ・パイポ・パイポのシューリンガンシューリンガンのグーリンダイグーリンダイのポンポコピーのポンポコナの長久命ちょうきゅうめいの長助';

    //テスト挿入
    await db.insert(
      'bookData', // テーブル名
      {
        'title': longtext,
        'author': '渡辺 博', // カラム名: 値
        'imagePath': 'testImagePath2', // カラム名: 値
        'isbnCode': '0000000000000',
        'comment': 'testComment2\n$longtext',
        'score': '2',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );

    //20のテスト挿入
    for(int i= 0;i<20;i++){
      await db.insert(
      'bookData', // テーブル名
      {
        'title': 'test${i.toString()}', // カラム名: 値
        'author': 'testName${i.toString()}', // カラム名: 値
        'imagePath': 'testImagePath', // カラム名: 値
        'isbnCode': '0000000000000',
        'comment': 'testComment${i.toString()}',
        'score': '3',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
    }
*/

    return db;
  }

  // アイテムを取得するメソッド
  Future<List<Map<String, dynamic>>> getItems([int? id]) async {
    final db = await database; // データベースのインスタンスを取得

    if (id == null) {
      //idを指定しない場合、全てを返す
      return await db.query(
        'bookData',
        //where: 'content = ?',
        //whereArgs: ['OK'], // "?"に代入する値
        orderBy: 'created_at DESC', // ソート順
        //limit: 3, // 取得件数
      ); // 'bookData' テーブルからすべてのデータを取得
    } else {
      //idを指定して一つを検索
      return await db.query(
        'bookData',
        where: 'id = ?',
        whereArgs: [id], // "?"に代入する値
        orderBy: 'created_at DESC', // ソート順
        //limit: 3, // 取得件数
      );
    }
  }

  //検索条件を指定してアイテムを検索する
  Future<List<Map<String, dynamic>>> searchItems(
    String searchString,
    bool isSearchComment,
    bool isSearchBookdata,
    List<bool> sortType,
    bool isAscending,
  ) async {
    final db = await database; // データベースのインスタンスを取得

    String query = "SELECT * FROM bookData ";

    if (searchString == "") {
    } else if (isSearchComment && isSearchBookdata ||
        !isSearchComment && !isSearchBookdata) {
      //コメントと本情報両方での検索
      query +=
          "where title like '%${searchString}%' or author like '%${searchString}%' or comment like '%${searchString}%' ";
    } else if (isSearchComment) {
      query += "where comment like '%${searchString}%' ";
    } else if (isSearchBookdata) {
      query +=
          "where title like '%${searchString}%' or author like '%${searchString}%' ";
    }

    if (sortType[0] == true) {
      //登録日でのソート
      query += "order by \"created_at\" ";
    } else {
      //評価でのソート
      query += "order by \"score\" ";
    }
    //昇順降順
    if (isAscending) {
      query += "ASC ";
    } else {
      query += "DESC ";
    }

    //query += "limit 10 offset ${showOffset.toString()}";

    return await db.rawQuery(query);
    /*
    return await db.query(
      'bookData',
      //where: 'content = ?',
      //whereArgs: ['OK'], // "?"に代入する値
      orderBy: 'created_at DESC', // ソート順
      //limit: 3, // 取得件数
    );
    */
  }

  // アイテムを追加するメソッド
  Future<void> insertItem(Map<String, dynamic> item) async {
    final db = await database; // データベースのインスタンスを取得
    await db.insert(
      'bookData',
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // アイテムを削除するメソッド
  Future<void> deleteItem(int id) async {
    //idのデータの画像パスを調べる
    List<Map<String, dynamic>> data = await getItems(id);
    //ファイルのパス
    String filePath = '${data[0]['imagePath']}';

    final File file = File(filePath);

    // ファイルを削除
    if (await file.exists()) {
      await file.delete();
    } else {}

    final db = await database;
    await db.delete('bookData', where: 'id = ?', whereArgs: [id]);
  }

  // アイテムを更新するメソッド
  Future<void> updateItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.update('bookData', item, where: 'id = ?', whereArgs: [item['id']]);
  }

  //isbnが一致するデータが既に存在するかを調べるメソッド
  Future<bool> isExistItem(String isbnCode) async {
    final db = await database;

    List<Map<String, dynamic>> map = await db.query(
      'bookData',
      where: 'isbnCode = ?',
      whereArgs: [isbnCode], // "?"に代入する値
      orderBy: 'created_at DESC', // ソート順
      //limit: 3, // 取得件数
    );

    if(map.isEmpty){
      //存在しない
      return false;
    }else{
      //存在する
      return true;
    }
  }
}
