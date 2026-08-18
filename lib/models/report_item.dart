class ReportItem {
  final String title;
  final String date;

  ReportItem({required this.title, required this.date});

  Map<String, String> toMap() => {'title': title, 'date': date};

  factory ReportItem.fromMap(Map<String, String> map) =>
      ReportItem(title: map['title'] ?? '', date: map['date'] ?? '');
}