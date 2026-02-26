import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotePadHome extends StatefulWidget {
  const NotePadHome({super.key});

  @override
  State<NotePadHome> createState() => _NotePadHomeState();
}

class _NotePadHomeState extends State<NotePadHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _showArchived = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic ts) {
    if (ts is! Timestamp) return '';
    final dt = ts.toDate().toLocal();
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    final hh = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$dd/$mm/$yy  $hh:$min $ampm';
  }

  Future<void> _openEditor({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NoteEditorPage(
          doc: doc,
          firestore: _firestore,
        ),
      ),
    );
  }

  Future<void> _archiveNote(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive note'),
        content: const Text('Move this note to archive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _firestore.collection('notes').doc(docId).update({
      'is_archived': true,
      'archived_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note archived')),
    );
  }

  Future<void> _restoreNote(String docId) async {
    await _firestore.collection('notes').doc(docId).update({
      'is_archived': false,
      'archived_at': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note restored')),
    );
  }

  Future<void> _deleteFromArchive(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete permanently'),
        content: const Text(
          'This note is in archive. Delete it permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _firestore.collection('notes').doc(docId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note permanently deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notepad')),
      floatingActionButton: _showArchived
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('New Note'),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Notes'),
                  selected: !_showArchived,
                  onSelected: (_) => setState(() => _showArchived = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Archived'),
                  selected: _showArchived,
                  onSelected: (_) => setState(() => _showArchived = true),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchText = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('notes')
                  .orderBy('updated_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data();
                  final archived = (data['is_archived'] ?? false) == true;
                  if (archived != _showArchived) return false;
                  if (_searchText.isEmpty) return true;
                  final title = '${data['title'] ?? ''}'.toLowerCase();
                  final body = '${data['body'] ?? ''}'.toLowerCase();
                  return title.contains(_searchText) || body.contains(_searchText);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No notes found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final title = '${data['title'] ?? ''}'.trim();
                    final body = '${data['body'] ?? ''}'.trim();
                    final updated = _formatDate(data['updated_at']);

                    return Card(
                      child: ListTile(
                        onTap: () => _openEditor(doc: doc),
                        title: Text(
                          title.isEmpty ? '(No title)' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              updated,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                        trailing: _showArchived
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Restore',
                                    onPressed: () => _restoreNote(doc.id),
                                    icon: const Icon(Icons.restore),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete permanently',
                                    onPressed: () => _deleteFromArchive(doc.id),
                                    icon: const Icon(Icons.delete_forever),
                                  ),
                                ],
                              )
                            : IconButton(
                                tooltip: 'Archive',
                                onPressed: () => _archiveNote(doc.id),
                                icon: const Icon(Icons.archive_outlined),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteEditorPage extends StatefulWidget {
  const _NoteEditorPage({
    required this.firestore,
    this.doc,
  });

  final FirebaseFirestore firestore;
  final DocumentSnapshot<Map<String, dynamic>>? doc;

  @override
  State<_NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<_NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _saving = false;
  String _initialTitle = '';
  String _initialBody = '';

  bool get _isEdit => widget.doc != null;
  bool get _hasUnsavedChanges =>
      _titleController.text.trim() != _initialTitle ||
      _bodyController.text.trim() != _initialBody;

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data();
    _initialTitle = '${data?['title'] ?? ''}'.trim();
    _initialBody = '${data?['body'] ?? ''}'.trim();
    _titleController = TextEditingController(text: _initialTitle);
    _bodyController = TextEditingController(text: _initialBody);
    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _bodyController.removeListener(_onTextChanged);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _undoChanges() {
    if (!_hasUnsavedChanges) return;
    _titleController.text = _initialTitle;
    _bodyController.text = _initialBody;
    _titleController.selection = TextSelection.collapsed(
      offset: _titleController.text.length,
    );
    _bodyController.selection = TextSelection.collapsed(
      offset: _bodyController.text.length,
    );
    setState(() {});
  }

  Future<void> _save({bool closeAfterSave = true}) async {
    if (_saving) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something')),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (_isEdit) {
      await widget.firestore.collection('notes').doc(widget.doc!.id).update(payload);
    } else {
      await widget.firestore.collection('notes').add({
        ...payload,
        'is_archived': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    _initialTitle = title;
    _initialBody = body;

    if (!mounted) return;
    if (closeAfterSave) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<bool> _confirmExit() async {
    if (!_hasUnsavedChanges) return true;

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text('You have unsaved changes. Save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Don\'t Save'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (action == 'save') {
      await _save(closeAfterSave: false);
      return true;
    }
    if (action == 'discard') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allowExit = await _confirmExit();
        if (!mounted || !allowExit) return;
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Note' : 'New Note'),
          actions: [
            TextButton.icon(
              onPressed: (_saving || !_hasUnsavedChanges) ? null : _undoChanges,
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
            ),
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    labelText: 'Write your note...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
