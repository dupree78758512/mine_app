import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mine_app/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TodoItem Unit Tests', () {
    test('toMap and fromMap serialization', () {
      final now = DateTime.now();
      final todo = TodoItem(
        id: '123',
        title: 'Test Title',
        description: 'Test Description',
        isCompleted: true,
        createdAt: now,
      );

      final map = todo.toMap();
      expect(map['id'], '123');
      expect(map['title'], 'Test Title');
      expect(map['description'], 'Test Description');
      expect(map['isCompleted'], true);
      expect(map['createdAt'], now.toIso8601String());

      final decoded = TodoItem.fromMap(map);
      expect(decoded.id, '123');
      expect(decoded.title, 'Test Title');
      expect(decoded.description, 'Test Description');
      expect(decoded.isCompleted, true);
      expect(decoded.createdAt, now);
    });
  });

  group('TodoListScreen Widget Tests', () {
    testWidgets('Displays empty state initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Mine App - To-Do List'), findsOneWidget);
      expect(find.text('No todos yet!'), findsOneWidget);
      expect(find.text('Add one above to get started'), findsOneWidget);
    });

    testWidgets('Shows validation SnackBar when trying to add empty title', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap on add todo with empty fields
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('Can successfully add a todo item', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byType(TextField).at(0), 'Buy Groceries');
      // Enter description
      await tester.enterText(find.byType(TextField).at(1), 'Milk, Eggs, Bread');

      // Tap on Add Todo
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Check if SnackBar and item are shown
      expect(find.text('Todo added successfully!'), findsOneWidget);
      expect(find.text('Buy Groceries'), findsOneWidget);
      expect(find.text('Milk, Eggs, Bread'), findsOneWidget);
      expect(find.text('No todos yet!'), findsNothing);
    });

    testWidgets('Can toggle a todo item completed state', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Add a todo
      await tester.enterText(find.byType(TextField).at(0), 'Task 1');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify task text does not have strikethrough/is not completed yet
      final taskTextBefore = tester.widget<Text>(find.text('Task 1'));
      expect(taskTextBefore.style?.decoration, isNot(TextDecoration.lineThrough));

      // Toggle state via Checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify task text now has strikethrough/is completed
      final taskTextAfter = tester.widget<Text>(find.text('Task 1'));
      expect(taskTextAfter.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('Can delete a todo and undo deletion', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Add a todo
      await tester.enterText(find.byType(TextField).at(0), 'Delete Me');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsOneWidget);

      // Open the popup menu button
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      // Tap on Delete item
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify item is removed and SnackBar is shown
      expect(find.text('Delete Me'), findsNothing);
      expect(find.text('Todo deleted'), findsOneWidget);

      // Tap on Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Verify item is restored
      expect(find.text('Delete Me'), findsOneWidget);
    });

    testWidgets('Can edit an existing todo item', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Add a todo
      await tester.enterText(find.byType(TextField).at(0), 'Original Title');
      await tester.enterText(find.byType(TextField).at(1), 'Original Desc');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      // Tap on Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Verify the edit dialog is shown
      expect(find.text('Edit Todo'), findsOneWidget);

      // Enter new values in the text fields inside the dialog
      final dialogFinder = find.byType(AlertDialog);
      final titleFieldFinder = find.descendant(of: dialogFinder, matching: find.byType(TextField)).at(0);
      final descFieldFinder = find.descendant(of: dialogFinder, matching: find.byType(TextField)).at(1);

      await tester.enterText(titleFieldFinder, 'Updated Title');
      await tester.enterText(descFieldFinder, 'Updated Desc');

      // Tap on Update
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Verify updated values are displayed on screen
      expect(find.text('Updated Title'), findsOneWidget);
      expect(find.text('Updated Desc'), findsOneWidget);
      expect(find.text('Original Title'), findsNothing);
    });
  });
}
