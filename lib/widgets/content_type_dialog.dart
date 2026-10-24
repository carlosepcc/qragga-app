import 'package:flutter/material.dart';

enum QuickContentType {
  url,
  wifi,
  vcard,
  email,
  sms,
  phone,
  geo,
  plainText,
}

class ContentTypeDialogHelper {
  static Future<String?> showQuickContentPicker(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Content Formatters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a template to generate structured QR standard formats',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildTemplateChip(
                      ctx,
                      icon: Icons.link,
                      label: 'Website / URL',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final res = await _showUrlDialog(context);
                        if (res != null) Navigator.of(context).pop(res);
                      },
                    ),
                    _buildTemplateChip(
                      ctx,
                      icon: Icons.wifi,
                      label: 'Wi-Fi Network',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final res = await _showWifiDialog(context);
                        if (res != null) Navigator.of(context).pop(res);
                      },
                    ),
                    _buildTemplateChip(
                      ctx,
                      icon: Icons.contact_page,
                      label: 'vCard Contact',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final res = await _showVCardDialog(context);
                        if (res != null) Navigator.of(context).pop(res);
                      },
                    ),
                    _buildTemplateChip(
                      ctx,
                      icon: Icons.email,
                      label: 'Email (mailto)',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final res = await _showEmailDialog(context);
                        if (res != null) Navigator.of(context).pop(res);
                      },
                    ),
                    _buildTemplateChip(
                      ctx,
                      icon: Icons.sms,
                      label: 'SMS Message',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final res = await _showSmsDialog(context);
                        if (res != null) Navigator.of(context).pop(res);
                      },
                    ),
                    _buildTemplateChip(
                      ctx,
                      icon: Icons.phone,
                      label: 'Phone Call',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final res = await _showPhoneDialog(context);
                        if (res != null) Navigator.of(context).pop(res);
                      },
                    ),
                    _buildTemplateChip(
                      ctx,
                      icon: Icons.location_on,
                      label: 'Geo Location',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final res = await _showGeoDialog(context);
                        if (res != null) Navigator.of(context).pop(res);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildTemplateChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static Future<String?> _showUrlDialog(BuildContext context) async {
    final controller = TextEditingController(text: 'https://');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Website Link'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Web Address (URL)',
            hintText: 'https://example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isNotEmpty ? text : null);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  static Future<String?> _showWifiDialog(BuildContext context) async {
    final ssidController = TextEditingController();
    final passController = TextEditingController();
    String authType = 'WPA';
    bool hidden = false;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Wi-Fi Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ssidController,
                  decoration: const InputDecoration(
                    labelText: 'Network Name (SSID)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: authType,
                  decoration: const InputDecoration(
                    labelText: 'Security Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2 / WPA3')),
                    DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                    DropdownMenuItem(value: 'nopass', child: Text('Open / No Password')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => authType = val);
                  },
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Hidden Network'),
                  value: hidden,
                  onChanged: (val) => setState(() => hidden = val ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final ssid = ssidController.text.trim();
                final pass = passController.text.trim();
                final h = hidden ? 'true' : 'false';
                // WIFI:T:WPA;S:MySSID;P:MyPassword;H:false;;
                final wifiString = 'WIFI:T:$authType;S:$ssid;P:$pass;H:$h;;';
                Navigator.pop(ctx, wifiString);
              },
              child: const Text('Generate Wi-Fi QR'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String?> _showVCardDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final orgController = TextEditingController();
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Card (vCard)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: orgController,
                decoration: const InputDecoration(labelText: 'Company / Organization', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Job Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Website', border: OutlineInputBorder()),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final vcard = StringBuffer();
              vcard.writeln('BEGIN:VCARD');
              vcard.writeln('VERSION:3.0');
              if (nameController.text.isNotEmpty) vcard.writeln('FN:${nameController.text.trim()}');
              if (phoneController.text.isNotEmpty) vcard.writeln('TEL:${phoneController.text.trim()}');
              if (emailController.text.isNotEmpty) vcard.writeln('EMAIL:${emailController.text.trim()}');
              if (orgController.text.isNotEmpty) vcard.writeln('ORG:${orgController.text.trim()}');
              if (titleController.text.isNotEmpty) vcard.writeln('TITLE:${titleController.text.trim()}');
              if (urlController.text.isNotEmpty) vcard.writeln('URL:${urlController.text.trim()}');
              vcard.writeln('END:VCARD');
              Navigator.pop(ctx, vcard.toString().trim());
            },
            child: const Text('Generate vCard'),
          ),
        ],
      ),
    );
  }

  static Future<String?> _showEmailDialog(BuildContext context) async {
    final toController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: toController,
              decoration: const InputDecoration(labelText: 'Recipient Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final to = toController.text.trim();
              final sub = Uri.encodeComponent(subjectController.text.trim());
              final body = Uri.encodeComponent(bodyController.text.trim());
              final mailto = 'mailto:$to?subject=$sub&body=$body';
              Navigator.pop(ctx, mailto);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  static Future<String?> _showSmsDialog(BuildContext context) async {
    final phoneController = TextEditingController();
    final msgController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SMS QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: msgController,
              decoration: const InputDecoration(labelText: 'Message Text', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              final msg = msgController.text.trim();
              final sms = 'SMSTO:$phone:$msg';
              Navigator.pop(ctx, sms);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  static Future<String?> _showPhoneDialog(BuildContext context) async {
    final phoneController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Telephone QR'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              Navigator.pop(ctx, phone.isNotEmpty ? 'tel:$phone' : null);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  static Future<String?> _showGeoDialog(BuildContext context) async {
    final latController = TextEditingController();
    final lngController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geolocation QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitude (e.g. 40.7128)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(labelText: 'Longitude (e.g. -74.0060)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final lat = latController.text.trim();
              final lng = lngController.text.trim();
              if (lat.isNotEmpty && lng.isNotEmpty) {
                Navigator.pop(ctx, 'geo:$lat,$lng');
              } else {
                Navigator.pop(ctx, null);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
