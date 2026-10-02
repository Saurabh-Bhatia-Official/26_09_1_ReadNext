class PdfDocumentMeta {
  final String title;
  final String author;
  final String subject;
  final String keywords;
  final String creator;
  final String producer;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final int pageCount;
  final int fileSize;
  final String filePath;
  final bool isEncrypted;
  final String pdfVersion;

  const PdfDocumentMeta({
    required this.title,
    this.author = '',
    this.subject = '',
    this.keywords = '',
    this.creator = '',
    this.producer = '',
    this.creationDate,
    this.modificationDate,
    required this.pageCount,
    required this.fileSize,
    required this.filePath,
    this.isEncrypted = false,
    this.pdfVersion = '1.7',
  });

  factory PdfDocumentMeta.empty() {
    return const PdfDocumentMeta(
      title: 'Untitled',
      pageCount: 0,
      fileSize: 0,
      filePath: '',
    );
  }

  PdfDocumentMeta copyWith({
    String? title,
    String? author,
    String? subject,
    String? keywords,
    String? creator,
    String? producer,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? pageCount,
    int? fileSize,
    String? filePath,
    bool? isEncrypted,
    String? pdfVersion,
  }) {
    return PdfDocumentMeta(
      title: title ?? this.title,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      keywords: keywords ?? this.keywords,
      creator: creator ?? this.creator,
      producer: producer ?? this.producer,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      pageCount: pageCount ?? this.pageCount,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      pdfVersion: pdfVersion ?? this.pdfVersion,
    );
  }
}
