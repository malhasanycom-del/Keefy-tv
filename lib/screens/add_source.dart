import 'package:flutter/material.dart';
import '../models.dart';
import '../services/store.dart';

class AddSourceScreen extends StatefulWidget {
  const AddSourceScreen({super.key});

  @override
  State<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends State<AddSourceScreen> {
  String type = 'm3u';
  final name = TextEditingController();
  final url = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();
  final mac = TextEditingController();

  Widget field(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: !obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> save() async {
    final sourceUrl = url.text.trim();
    if (sourceUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رابط المصدر')),
      );
      return;
    }
    if (type == 'm3u' && Uri.tryParse(sourceUrl)?.hasScheme != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط M3U غير صحيح')),
      );
      return;
    }
    if (type == 'xtream' && (user.text.trim().isEmpty || pass.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل اسم المستخدم وكلمة المرور')),
      );
      return;
    }
    if (type == 'stalker' && mac.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان MAC')),
      );
      return;
    }

    final list = Store.sources();
    final source = Source(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.text.trim().isEmpty ? 'مصدر ${list.length + 1}' : name.text.trim(),
      type: type,
      url: sourceUrl,
      user: user.text.trim(),
      pass: pass.text,
      mac: mac.text.trim().toUpperCase(),
    );
    list.add(source);
    await Store.saveSources(list);
    await Store.setActive(source.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    name.dispose();
    url.dispose();
    user.dispose();
    pass.dispose();
    mac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مصدر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'm3u', label: Text('M3U')),
              ButtonSegment(value: 'xtream', label: Text('Xtream')),
              ButtonSegment(value: 'stalker', label: Text('Stalker')),
            ],
            selected: {type},
            onSelectionChanged: (values) => setState(() => type = values.first),
          ),
          field('اسم المصدر', name),
          field(
            type == 'm3u'
                ? 'رابط M3U'
                : type == 'xtream'
                    ? 'رابط السيرفر http://host:port'
                    : 'رابط البورتال',
            url,
          ),
          if (type == 'xtream') ...[
            field('اسم المستخدم', user),
            field('كلمة المرور', pass, obscure: true),
          ],
          if (type == 'stalker') field('MAC (00:1A:79:XX:XX:XX)', mac),
          const SizedBox(height: 20),
          FilledButton(onPressed: save, child: const Text('حفظ')),
        ],
      ),
    );
  }
}
