/// Categories available when recording an expense.
///
/// The enum name is persisted in local storage, so renaming a value would
/// require a storage migration. Display labels are kept separate from names.
enum ExpenseCategory {
  food('Food'),
  transport('Transport'),
  shopping('Shopping'),
  bills('Bills'),
  entertainment('Entertainment'),
  health('Health'),
  education('Education'),
  other('Other');

  const ExpenseCategory(this.label);

  final String label;
}
