import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'todo.dart';

/// Some keys used for testing
final addTodoKey = UniqueKey();
final activeFilterKey = UniqueKey();
final completedFilterKey = UniqueKey();
final allFilterKey = UniqueKey();

/// Creates a [TodoList] and initialise it with pre-defined values.
///
/// We are using [StateNotifierProvider] here as a `List<Todo>` is a complex
/// object, with advanced business logic like how to edit a todo.
final todoListProvider = StateNotifierProvider<TodoList, List<Todo>>((ref) {
  return TodoList(const [
    Todo(id: 'todo-0', description: 'hi'),
    Todo(id: 'todo-1', description: 'hello'),
    Todo(id: 'todo-2', description: 'bonjour'),
  ]);
});

/// The different ways to filter the list of todos
enum TodoListFilter {
  all,
  active,
  completed,
}

/// The currently active filter.
///
/// We use [StateProvider] here as there is no fancy logic behind manipulating
/// the value since it's just enum.
final todoListFilter = StateProvider((_) => TodoListFilter.all);

/// The number of uncompleted todos
///
/// By using [Provider], this value is cached, making it performant.\
/// Even multiple widgets try to read the number of uncompleted todos,
/// the value will be computed only once (until the todo-list changes).
///
/// This will also optimise unneeded rebuilds if the todo-list changes, but the
/// number of uncompleted todos doesn't (such as when editing a todo).
final uncompletedTodosCount = Provider<int>((ref) {
  return ref.watch(todoListProvider).where((todo) => !todo.completed).length;
});

/// The list of todos after applying of [todoListFilter].
///
/// This too uses [Provider], to avoid recomputing the filtered list unless either
/// the filter of or the todo-list updates.
final filteredTodos = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoListFilter);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoListFilter.completed:
      return todos.where((todo) => todo.completed).toList();
    case TodoListFilter.active:
      return todos.where((todo) => !todo.completed).toList();
    case TodoListFilter.all:
      return todos;
  }
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformApp(
      debugShowCheckedModeBanner: false,
      material: (context, platform) => MaterialAppData(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
      cupertino: (context, platform) => CupertinoAppData(
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
        ),
      ),
      home: Home(),
    );
  }
}

class Home extends HookConsumerWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodos);
    final newTodoController = useTextEditingController();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PlatformScaffold(
        // appBar: PlatformAppBar(
        //   title: Text("To Do List"),
        // ),
        material: (context, platform) => MaterialScaffoldData(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            children: [
              const Title(),
              TextField(
                key: addTodoKey,
                controller: newTodoController,
                decoration: const InputDecoration(
                  labelText: 'What needs to be done?',
                ),
                onSubmitted: (value) {
                  ref.read(todoListProvider.notifier).add(value);
                  newTodoController.clear();
                },
              ),
              const SizedBox(height: 42),
              const Toolbar(),
              if (todos.isNotEmpty) const Divider(height: 0),
              for (var i = 0; i < todos.length; i++) ...[
                if (i > 0) const Divider(height: 0),
                Dismissible(
                  key: ValueKey(todos[i].id),
                  onDismissed: (_) {
                    ref.read(todoListProvider.notifier).remove(todos[i]);
                  },
                  child: ProviderScope(
                    overrides: [
                      _currentTodo.overrideWithValue(todos[i]),
                    ],
                    child: const TodoItem(),
                  ),
                )
              ],
            ],
          ),
        ),
        cupertino: (context, platform) => CupertinoPageScaffoldData(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            children: [
              const Title(),
              CupertinoTextField(
                key: addTodoKey,
                controller: newTodoController,
                onSubmitted: (value) {
                  ref.read(todoListProvider.notifier).add(value);
                  newTodoController.clear();
                },
              ),
              const SizedBox(height: 42),
              const Toolbar(),
              if (todos.isNotEmpty) const Divider(height: 0),
              for (var i = 0; i < todos.length; i++) ...[
                if (i > 0) const Divider(height: 0),
                Dismissible(
                  key: ValueKey(todos[i].id),
                  onDismissed: (_) {
                    ref.read(todoListProvider.notifier).remove(todos[i]);
                  },
                  child: ProviderScope(
                    overrides: [
                      _currentTodo.overrideWithValue(todos[i]),
                    ],
                    child: const TodoItem(),
                  ),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Toolbar extends HookConsumerWidget {
  const Toolbar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(todoListFilter);

    Color? textColorFor(TodoListFilter value) {
      return filter == value ? Colors.blue : Colors.black;
    }

    return PlatformWidget(
      material: (context, platform) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${ref.watch(uncompletedTodosCount)} items left',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            key: allFilterKey,
            message: 'All todos',
            child: TextButton(
              onPressed: () =>
                  ref.read(todoListFilter.notifier).state = TodoListFilter.all,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor:
                    MaterialStateProperty.all(textColorFor(TodoListFilter.all)),
              ),
              child: const Text('All'),
            ),
          ),
          Tooltip(
            key: activeFilterKey,
            message: 'Only uncompleted todos',
            child: TextButton(
              onPressed: () => ref.read(todoListFilter.notifier).state =
                  TodoListFilter.active,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TodoListFilter.active),
                ),
              ),
              child: const Text('Active'),
            ),
          ),
          Tooltip(
            key: completedFilterKey,
            message: 'Only completed todos',
            child: TextButton(
              onPressed: () => ref.read(todoListFilter.notifier).state =
                  TodoListFilter.completed,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TodoListFilter.completed),
                ),
              ),
              child: const Text('Completed'),
            ),
          ),
        ],
      ),
      cupertino: (context, platform) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${ref.watch(uncompletedTodosCount)} items left',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CupertinoButton(
            onPressed: () =>
                ref.read(todoListFilter.notifier).state = TodoListFilter.all,
            padding: EdgeInsets.zero,
            child: Text(
              'All',
              style: TextStyle(
                color: textColorFor(TodoListFilter.all),
              ),
            ),
          ),
          CupertinoButton(
            onPressed: () =>
                ref.read(todoListFilter.notifier).state = TodoListFilter.active,
            padding: EdgeInsets.zero,
            child: Text(
              'Active',
              style: TextStyle(
                color: textColorFor(TodoListFilter.active),
              ),
            ),
          ),
          CupertinoButton(
            onPressed: () => ref.read(todoListFilter.notifier).state =
                TodoListFilter.completed,
            padding: EdgeInsets.zero,
            child: Text(
              'Completed',
              style: TextStyle(
                color: textColorFor(TodoListFilter.completed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Title extends StatelessWidget {
  const Title({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'todos',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.fromARGB(38, 47, 47, 247),
        fontSize: 100,
        fontWeight: FontWeight.w100,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}

/// A provider which exposes the [Todo] displayed by a [TodoItem].
///
/// By retrieving the [Todo] through a provider instead of through its
/// constructor, this allows [TodoItem] to be instantiated using the `const` keyword.
///
/// This ensures that when we add/remove/edit todos, only what the
/// impacted widgets rebuilds, instead of the entire list of items.
final _currentTodo = Provider<Todo>((ref) => throw UnimplementedError());

class TodoItem extends HookConsumerWidget {
  const TodoItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(_currentTodo);
    final itemFocusNode = useFocusNode();
    final itemIsFocused = useIsFocused(itemFocusNode);

    final textEditingController = useTextEditingController();
    final textFieldFocusNode = useFocusNode();

    return PlatformWidget(
      material: (context, platform) => Material(
        color: Colors.white,
        elevation: 6,
        child: Focus(
          focusNode: itemFocusNode,
          onFocusChange: (focused) {
            if (focused) {
              textEditingController.text = todo.description;
            } else {
              // Commit changes only when the textfield is unfocused, for performance
              ref
                  .read(todoListProvider.notifier)
                  .edit(id: todo.id, description: textEditingController.text);
            }
          },
          child: ListTile(
            onTap: () {
              itemFocusNode.requestFocus();
              textFieldFocusNode.requestFocus();
            },
            leading: Checkbox(
              value: todo.completed,
              onChanged: (value) =>
                  ref.read(todoListProvider.notifier).toggle(todo.id),
            ),
            title: itemIsFocused
                ? TextField(
                    focusNode: textFieldFocusNode,
                    controller: textEditingController,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  )
                : Text(
                    todo.description,
                    style: TextStyle(
                      fontSize: 18,
                      decoration: todo.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
          ),
        ),
      ),
      cupertino: (context, platform) => CupertinoListTile(
        leading: CupertinoCheckbox(
          value: todo.completed,
          onChanged: (value) =>
              ref.read(todoListProvider.notifier).toggle(todo.id),
        ),
        title: itemIsFocused
            ? CupertinoTextField(
                focusNode: textFieldFocusNode,
                controller: textEditingController,
                style: const TextStyle(
                  fontSize: 18,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.inactiveGray,
                    ),
                  ),
                ),
              )
            : Text(
                todo.description,
                style: TextStyle(
                  fontSize: 18,
                  decoration: todo.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
      ),
    );
  }
}

bool useIsFocused(FocusNode node) {
  final isFocused = useState(node.hasFocus);

  useEffect(
    () {
      void listener() {
        isFocused.value = node.hasFocus;
      }

      node.addListener(listener);
      return () => node.removeListener(listener);
    },
    [node],
  );

  return isFocused.value;
}
