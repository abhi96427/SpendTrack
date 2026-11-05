import 'expense_category.dart';

/// A single expense record.
///
/// Models are immutable and contain no Flutter dependencies, which keeps them
/// safe to use from storage, providers, and tests.
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;

  /// The date the expense belongs to (time component is ignored by the UI).
  final DateTime date;

  /// When the record was first created, used as a stable sort tie-breaker.
  final DateTime createdAt;

  final String? note;

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    DateTime? createdAt,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  /// Parses a persisted record.
  ///
  /// Throws a [FormatException] when required fields are missing or invalid so
  /// the storage layer can report a clear, actionable error to the user.
  factory Expense.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final amount = json['amount'];
    final rawDate = json['date'];
    final rawCreatedAt = json['createdAt'];
    final rawCategory = json['category'];
    final rawNote = json['note'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Expense id is missing.');
    }
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('Expense title is missing.');
    }
    if (amount is! num || !amount.isFinite || amount <= 0) {
      throw const FormatException('Expense amount is invalid.');
    }

    final date = DateTime.tryParse(rawDate is String ? rawDate : '');
    if (date == null) {
      throw const FormatException('Expense date is invalid.');
    }

    final createdAt =
        DateTime.tryParse(rawCreatedAt is String ? rawCreatedAt : '') ?? date;

    final category = ExpenseCategory.values.firstWhere(
      (value) => value.name == rawCategory,
      orElse: () => ExpenseCategory.other,
    );

    final note = rawNote is String && rawNote.trim().isNotEmpty
        ? rawNote.trim()
        : null;

    return Expense(
      id: id,
      title: title.trim(),
      amount: amount.toDouble(),
      category: category,
      date: date.toLocal(),
      createdAt: createdAt.toLocal(),
      note: note,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Expense &&
            other.id == id &&
            other.title == title &&
            other.amount == amount &&
            other.category == category &&
            other.date == date &&
            other.createdAt == createdAt &&
            other.note == note;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, amount, category, date, createdAt, note);

  @override
  String toString() => 'Expense(id: $id, title: $title, amount: $amount)';
}
