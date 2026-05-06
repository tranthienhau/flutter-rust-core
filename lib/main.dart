import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/providers.dart';

void main() {
  runApp(const ProviderScope(child: RustCoreApp()));
}

class RustCoreApp extends StatelessWidget {
  const RustCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter-rust-core',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(coreVersionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Rust core v$version'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            _HashCard(),
            SizedBox(height: 16),
            _EmailCard(),
            SizedBox(height: 16),
            _JsonCard(),
          ],
        ),
      ),
    );
  }
}

class _HashCard extends ConsumerWidget {
  const _HashCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digest = ref.watch(hashControllerProvider);
    return _Section(
      title: 'SHA-256 (Rust)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Plaintext'),
            onChanged: ref.read(hashControllerProvider.notifier).compute,
          ),
          const SizedBox(height: 8),
          SelectableText(digest.isEmpty ? '(empty)' : digest,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmailCard extends ConsumerWidget {
  const _EmailCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valid = ref.watch(emailControllerProvider);
    final label = switch (valid) { null => '-', true => 'valid', false => 'invalid' };
    final color = switch (valid) {
      null => Colors.grey,
      true => Colors.green,
      false => Colors.red,
    };
    return _Section(
      title: 'Email check (Rust)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Email'),
            onChanged: ref.read(emailControllerProvider.notifier).check,
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _JsonCard extends ConsumerWidget {
  const _JsonCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final out = ref.watch(jsonControllerProvider);
    return _Section(
      title: 'JSON enrich (Rust)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'JSON object',
              hintText: '{"id": 42}',
            ),
            onChanged: ref.read(jsonControllerProvider.notifier).enrich,
          ),
          const SizedBox(height: 8),
          SelectableText(out ?? '(empty)',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
