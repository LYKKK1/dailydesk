import 'package:dailydesk/features/copilot/services/ai_service.dart';
import 'package:flutter/material.dart';

typedef AiFetchModels = Future<List<String>> Function({
  required String baseUrl,
  required String apiKey,
  String? proxy,
});

typedef AiDeconstructIdea = Future<Deconstruction> Function({
  required String idea,
  required String baseUrl,
  required String apiKey,
  required String model,
  String? proxy,
});

typedef AiBatchApply = Future<void> Function(Deconstruction deconstruction);

class AiChatView extends StatefulWidget {
  const AiChatView({
    super.key,
    this.fetchModels,
    this.deconstructIdea,
    this.onApply,
  });

  final AiFetchModels? fetchModels;
  final AiDeconstructIdea? deconstructIdea;
  final AiBatchApply? onApply;

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  static const _baseUrlPresets = <String, String>{
    'OpenAI': 'https://api.openai.com/v1',
    'DeepSeek': 'https://api.deepseek.com/v1',
    'Groq': 'https://api.groq.com/openai/v1',
    'Moonshot': 'https://api.moonshot.cn/v1',
    'Ollama': 'http://127.0.0.1:11434/v1',
  };

  final _baseUrlController =
      TextEditingController(text: 'https://api.openai.com/v1');
  final _apiKeyController = TextEditingController();
  final _proxyController = TextEditingController(text: 'http://127.0.0.1:7890');
  final _modelController = TextEditingController();
  final _ideaController = TextEditingController();

  List<String> _models = const [];
  Deconstruction? _result;
  Set<int> _selectedTodos = {};
  Set<int> _selectedSops = {};
  Set<int> _selectedMemos = {};
  String? _error;
  bool _loadingModels = false;
  bool _deconstructing = false;
  bool _applying = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _proxyController.dispose();
    _modelController.dispose();
    _ideaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'AI 智囊',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: '服务模板',
                icon: const Icon(Icons.hub_outlined),
                onSelected: (value) {
                  _baseUrlController.text = value;
                  setState(() {});
                },
                itemBuilder: (context) => [
                  for (final preset in _baseUrlPresets.entries)
                    PopupMenuItem(value: preset.value, child: Text(preset.key)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('ai-base-url'),
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('ai-api-key'),
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              helperText: '仅保存在当前会话内存中',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('ai-proxy'),
            controller: _proxyController,
            decoration: const InputDecoration(
              labelText: '代理地址',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _models.isEmpty
                    ? TextField(
                        key: const Key('ai-model'),
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: '模型',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        key: const Key('ai-model'),
                        value: _models.contains(_modelController.text)
                            ? _modelController.text
                            : null,
                        decoration: const InputDecoration(
                          labelText: '模型',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final model in _models)
                            DropdownMenuItem(value: model, child: Text(model)),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          _modelController.text = value;
                          setState(() {});
                        },
                      ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _loadingModels ? null : _loadModels,
                icon: _loadingModels
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('获取模型列表'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('ai-idea'),
            controller: _ideaController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '想法',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _deconstructing ? null : _deconstruct,
            icon: _deconstructing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text('开始拆解'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 18),
            Text(_result!.analysis, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            _buildTodos(),
            const SizedBox(height: 10),
            _buildSops(),
            const SizedBox(height: 10),
            _buildMemos(),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: _applying ? null : _apply,
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('一键写入工作台'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodos() {
    final todos = _result!.todos;
    return _ActionGroup(
      icon: Icons.checklist_rtl,
      title: '待办',
      children: [
        for (var index = 0; index < todos.length; index++)
          CheckboxListTile(
            key: Key('select-todo-$index'),
            value: _selectedTodos.contains(index),
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(todos[index].title),
            subtitle: Text(
              'P${todos[index].priority} · '
              '${todos[index].estimatedPomodoros} 个番茄'
              '${todos[index].dueTime == null ? '' : ' · ${todos[index].dueTime}'}',
            ),
            onChanged: (selected) => _toggle(_selectedTodos, index, selected),
          ),
      ],
    );
  }

  Widget _buildSops() {
    final sops = _result!.sops;
    return _ActionGroup(
      icon: Icons.view_list_outlined,
      title: 'SOP',
      children: [
        for (var index = 0; index < sops.length; index++)
          CheckboxListTile(
            key: Key('select-sop-$index'),
            value: _selectedSops.contains(index),
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(sops[index].title),
            subtitle: Text(sops[index].time),
            onChanged: (selected) => _toggle(_selectedSops, index, selected),
          ),
      ],
    );
  }

  Widget _buildMemos() {
    final memos = _result!.memos;
    return _ActionGroup(
      icon: Icons.lightbulb_outline,
      title: '便签',
      children: [
        for (var index = 0; index < memos.length; index++)
          CheckboxListTile(
            key: Key('select-memo-$index'),
            value: _selectedMemos.contains(index),
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(memos[index].content),
            subtitle: memos[index].tag == null ? null : Text(memos[index].tag!),
            onChanged: (selected) => _toggle(_selectedMemos, index, selected),
          ),
      ],
    );
  }

  void _toggle(Set<int> selected, int index, bool? value) {
    setState(() {
      if (value ?? false) {
        selected.add(index);
      } else {
        selected.remove(index);
      }
    });
  }

  Future<void> _loadModels() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _error = '请先填写 API Key');
      return;
    }

    setState(() {
      _loadingModels = true;
      _error = null;
    });
    try {
      final fetch = widget.fetchModels ?? AiService.fetchModels;
      final models = await fetch(
        baseUrl: _baseUrlController.text.trim(),
        apiKey: apiKey,
        proxy: _proxyController.text,
      );
      if (!mounted) return;
      setState(() {
        _models = models;
        if (models.isNotEmpty && _modelController.text.trim().isEmpty) {
          _modelController.text = models.first;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _deconstruct() async {
    final apiKey = _apiKeyController.text.trim();
    final model = _modelController.text.trim();
    final idea = _ideaController.text.trim();
    if (apiKey.isEmpty || model.isEmpty || idea.isEmpty) {
      setState(() => _error = '请填写 API Key、模型和想法');
      return;
    }

    setState(() {
      _deconstructing = true;
      _error = null;
    });
    try {
      final deconstruct = widget.deconstructIdea ?? AiService.deconstructIdea;
      final result = await deconstruct(
        idea: idea,
        baseUrl: _baseUrlController.text.trim(),
        apiKey: apiKey,
        model: model,
        proxy: _proxyController.text,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _selectedTodos = {for (var i = 0; i < result.todos.length; i++) i};
        _selectedSops = {for (var i = 0; i < result.sops.length; i++) i};
        _selectedMemos = {for (var i = 0; i < result.memos.length; i++) i};
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _deconstructing = false);
    }
  }

  Future<void> _apply() async {
    final result = _result;
    if (result == null) return;

    final selected = Deconstruction(
      result.analysis,
      [
        for (var i = 0; i < result.todos.length; i++)
          if (_selectedTodos.contains(i)) result.todos[i],
      ],
      [
        for (var i = 0; i < result.sops.length; i++)
          if (_selectedSops.contains(i)) result.sops[i],
      ],
      [
        for (var i = 0; i < result.memos.length; i++)
          if (_selectedMemos.contains(i)) result.memos[i],
      ],
    );

    if (widget.onApply == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('批量写入尚未配置')),
      );
      return;
    }

    setState(() => _applying = true);
    try {
      await widget.onApply!(selected);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
