import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'service/user_service.dart';

void main() {
  runApp(const CrudApp());
}

class CrudApp extends StatelessWidget {
  const CrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRUD REST API',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const UserPage(),
    );
  }
}

/// Dialog form tambah/edit user.
/// Controller dibuat dan di-dispose di dalam State dialog sendiri,
/// sehingga aman dari error "_dependents.isEmpty".
class _UserFormDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialJob;

  const _UserFormDialog({
    required this.title,
    required this.initialName,
    required this.initialJob,
  });

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _jobController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _jobController = TextEditingController(text: widget.initialJob);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'job': _jobController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jobController,
                decoration: const InputDecoration(
                  labelText: 'Pekerjaan',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pekerjaan wajib diisi';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserService service = UserService();

  late Future<List<UserModel>> usersFuture;
  final List<UserModel> localUsers = [];

  @override
  void initState() {
    super.initState();
    usersFuture = service.getUsers();
  }

  void reloadUsers() {
    setState(() {
      usersFuture = service.getUsers();
    });
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<Map<String, String>?> showUserForm({
    String name = '',
    String job = '',
    String title = 'Tambah User',
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => _UserFormDialog(
        title: title,
        initialName: name,
        initialJob: job,
      ),
    );
  }

  Future<void> createUser() async {
    final form = await showUserForm();
    if (form == null || !mounted) return;

    try {
      final result = await service.createUser(
        name: form['name']!,
        job: form['job']!,
      );

      if (!mounted) return;

      final parts = form['name']!.split(' ');

      final newUser = UserModel(
        id: int.tryParse('${result['id']}') ??
            DateTime.now().millisecondsSinceEpoch,
        email: '',
        firstName: parts.first,
        lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
        avatar: '',
      );

      setState(() {
        localUsers.insert(0, newUser);
      });

      showMessage(
        'Berhasil membuat user! ID: ${result['id'] ?? '-'}',
      );
    } catch (e) {
      showMessage('Gagal membuat user: $e');
    }
  }

  Future<void> editUser(UserModel user) async {
    final form = await showUserForm(
      name: '${user.firstName} ${user.lastName}'.trim(),
      job: 'Pekerjaan baru',
      title: 'Edit User #${user.id}',
    );

    if (form == null || !mounted) return;

    try {
      final result = await service.updateUser(
        id: user.id,
        name: form['name']!,
        job: form['job']!,
      );

      if (!mounted) return;

      final parts = form['name']!.split(' ');
      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        firstName: parts.first,
        lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
        avatar: user.avatar,
      );

      setState(() {
        final index = localUsers.indexWhere(
              (item) => item.id == user.id,
        );

        if (index >= 0) {
          localUsers[index] = updatedUser;
        } else {
          localUsers.insert(0, updatedUser);
        }
      });

      showMessage(
        'Berhasil memperbarui user! ${result['updatedAt'] ?? ''}',
      );
    } catch (e) {
      showMessage('Gagal memperbarui user: $e');
    }
  }

  Future<void> deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus User'),
          content: Text(
            'Yakin ingin menghapus ${user.firstName} ${user.lastName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await service.deleteUser(user.id);

      if (!mounted) return;

      setState(() {
        localUsers.removeWhere((item) => item.id == user.id);

        usersFuture = usersFuture.then(
              (users) => users.where((item) => item.id != user.id).toList(),
        );
      });

      showMessage('Berhasil menghapus user!');
    } catch (e) {
      showMessage('Gagal menghapus user: $e');
    }
  }

  Widget buildUserList(List<UserModel> users) {
    final allUsers = [
      ...localUsers,
      ...users.where(
            (user) => !localUsers.any((local) => local.id == user.id),
      ),
    ];

    if (allUsers.isEmpty) {
      return const Center(
        child: Text('Belum ada data user.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        reloadUsers();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: allUsers.length,
        itemBuilder: (context, index) {
          final user = allUsers[index];
          final fullName = '${user.firstName} ${user.lastName}'.trim();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundImage: user.avatar.isNotEmpty
                        ? NetworkImage(user.avatar)
                        : null,
                    child: user.avatar.isEmpty
                        ? Text(
                      user.firstName.isNotEmpty
                          ? user.firstName[0].toUpperCase()
                          : '?',
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'User #${user.id}' : fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('ID: ${user.id}'),
                        Text(
                          user.email.isEmpty ? 'Data demo' : user.email,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        editUser(user);
                      } else if (value == 'delete') {
                        deleteUser(user);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD REST API'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: reloadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text('GET • POST • PUT • DELETE'),
                Text('Data user dari REST API ReqRes'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Memuat data user...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Gagal memuat data user',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: reloadUsers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return buildUserList(snapshot.data ?? []);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createUser,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah User'),
      ),
    );
  }
}