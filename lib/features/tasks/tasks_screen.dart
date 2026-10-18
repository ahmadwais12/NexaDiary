import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterPriority = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.tasks,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterPriority = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text(l10n.allPriorities)),
              PopupMenuItem(value: 'urgent', child: Text(l10n.urgent)),
              PopupMenuItem(value: 'high', child: Text(l10n.high)),
              PopupMenuItem(value: 'medium', child: Text(l10n.medium)),
              PopupMenuItem(value: 'low', child: Text(l10n.low)),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Expired'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(l10n.allPriorities, 'all'),
                _buildFilterChip(l10n.urgent, 'urgent'),
                _buildFilterChip(l10n.high, 'high'),
                _buildFilterChip(l10n.medium, 'medium'),
                _buildFilterChip(l10n.low, 'low'),
              ],
            ),
          ),
          Expanded(
            child:              TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList('pending'),
                _buildTaskList('completed'),
                _buildTaskList('expired'),
                _buildTaskList('all'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hero_tasks_fab',
        onPressed: () => context.push('/task/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  void _showSearch() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.all(4),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '${l10n.search}...',
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Task>>(
                  stream: database.watchAllTasks(),
                  builder: (context, snapshot) {
                    final tasks = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? tasks
                        : tasks.where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()) || t.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        return ListTile(
                          leading: Icon(
                            task.status == 'completed' ? Icons.check_circle : Icons.circle_outlined,
                            color: task.status == 'completed' ? Colors.green : null,
                          ),
                          title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: task.description.isNotEmpty ? Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filterPriority == value,
        onSelected: (_) => setState(() => _filterPriority = value),
      ),
    );
  }

  Widget _buildTaskList(String status) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Task>>(
      stream: database.watchAllTasks(),
      builder: (context, snapshot) {
        final allTasks = snapshot.data ?? [];
        List<Task> tasks;
        if (status == 'all') {
          tasks = allTasks;
        } else if (status == 'expired') {
          tasks = allTasks.where((t) => t.status == 'expired').toList();
        } else {
          tasks = allTasks.where((t) => t.status == status).toList();
        }
        if (_filterPriority != 'all')
          tasks = tasks.where((t) => t.priority == _filterPriority).toList();
        if (_searchQuery.isNotEmpty)
          tasks = tasks.where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()) || t.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        tasks.sort((a, b) {
          final po = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
          final ap = po[a.priority] ?? 2, bp = po[b.priority] ?? 2;
          if (ap != bp) return ap.compareTo(bp);
          if (a.dueDate != null && b.dueDate != null)
            return a.dueDate!.compareTo(b.dueDate!);
          if (a.dueDate != null) return -1;
          if (b.dueDate != null) return 1;
          return 0;
        });

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  status == 'completed'
                      ? l10n.noCompletedTasks
                      : status == 'expired'
                          ? 'No expired tasks'
                          : l10n.noTasksForToday,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = task.status == 'completed';
    final isExpired = task.status == 'expired';
    final bgColor = parseColor(task.color);
    return Card(
      color: bgColor?.withValues(alpha: 0.12),
      shape: bgColor != null ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: bgColor.withValues(alpha: 0.25)),
      ) : null,
      child: InkWell(
        onTap: () => context.push('/task/${task.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isCompleted,
                onChanged: (value) async {
                  if (value == true) {
                    await database.completeTask(task.id);
                  } else {
                    // Restore from completed or expired to pending
                    await database.updateTask(
                      TasksCompanion(
                        id: Value(task.id),
                        status: const Value('pending'),
                        completedAt: const Value(null),
                      ),
                    );
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Left: content (title, body, date)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isExpired ? Colors.red.shade400 : (isCompleted ? Colors.grey : null),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Body
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    // Date + Priority
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildPriorityChip(task.priority),
                        if (isExpired) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Expired',
                              style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        if (task.dueDate != null && !isExpired) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    DateFormat('MMM d').format(task.dueDate!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Right: more icon (vertically centered)
              PopupMenuButton<String>(
                onSelected: (v) => _handleTaskAction(v, task),
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 28,
                  color: Colors.grey.shade600,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: const [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(isCompleted ? Icons.replay : Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 12),
                        Text(isCompleted ? l10n.markPending : l10n.markComplete),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTask(Task task) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Move to Trash?',
      itemName: task.title,
    );
    if (confirmed) {
      await notificationService.cancelTaskAlarm(task.id);
      await database.trashTask(task.id);
    }
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'urgent':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.blue;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleTaskAction(String action, Task task) async {
    switch (action) {
      case 'edit':
        context.push('/task/${task.id}');
        break;
      case 'complete':
        if (task.status == 'completed') {
          await database.updateTask(
            TasksCompanion(
              id: Value(task.id),
              status: const Value('pending'),
              completedAt: const Value(null),
            ),
          );
        } else {
          await database.completeTask(task.id);
        }
        break;
      case 'delete':
        _confirmDeleteTask(task);
        break;
    }
  }
}
