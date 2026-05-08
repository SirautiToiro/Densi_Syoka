class BookData{
    final String title;
    final String author;
    final String imageFileName;
    final String isbnCode;
    final String? comment;
    final int? id;
    final int? createdTime;
    final int? score;
    final bool alreadyExistFlag;

    //comment,id,createdTimeはオプション引数
    BookData(this.title,this.author,this.imageFileName,this.isbnCode,this.alreadyExistFlag,
    [this.comment,this.id,this.createdTime,this.score,]);
  }