import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  // Default settings
  String _selectedBrailleStandard = 'grade1';
  String _selectedLanguage = 'en';
  String _selectedTheme = 'light';
  bool _notificationsEnabled = true;
  bool _autoSaveTranslations = true;
  bool _includeMetadata = true;
  bool _formatOutput = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _authService.getUserData();
      if (userData != null && userData['settings'] != null) {
        final settings = userData['settings'] as Map<String, dynamic>;
        setState(() {
          _selectedBrailleStandard = settings['brailleStandard'] ?? 'grade1';
          _selectedLanguage = settings['language'] ?? 'en';
          _selectedTheme = settings['theme'] ?? 'light';
          _notificationsEnabled = settings['notifications'] ?? true;
          _autoSaveTranslations = settings['autoSaveTranslations'] ?? true;
          _includeMetadata = settings['includeMetadata'] ?? true;
          _formatOutput = settings['formatOutput'] ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    final updatedSettings = {
      'brailleStandard': _selectedBrailleStandard,
      'language': _selectedLanguage,
      'theme': _selectedTheme,
      'notifications': _notificationsEnabled,
      'autoSaveTranslations': _autoSaveTranslations,
      'includeMetadata': _includeMetadata,
      'formatOutput': _formatOutput,
    };

    try {
      await _authService.updateUserSettings(updatedSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Braille Translation Settings
                  _buildSectionCard(
                    title: 'Braille Translation',
                    icon: Icons.accessibility,
                    children: [
                      _buildDropdownSetting(
                        'Braille Standard',
                        _selectedBrailleStandard,
                        [
                          {
                            'value': 'grade1',
                            'label': 'Grade 1 (Uncontracted)'
                          },
                          {'value': 'grade2', 'label': 'Grade 2 (Contracted)'},
                          {'value': 'grade3', 'label': 'Grade 3 (Shorthand)'},
                          {'value': 'computer', 'label': 'Computer Braille'},
                          {'value': 'math', 'label': 'Math/Science'},
                          {'value': 'music', 'label': 'Music Notation'},
                        ],
                        (value) =>
                            setState(() => _selectedBrailleStandard = value),
                      ),
                      _buildDropdownSetting(
                        'Language',
                        _selectedLanguage,
                        [
                          {'value': 'en', 'label': 'English'},
                          {'value': 'es', 'label': 'Spanish'},
                          {'value': 'fr', 'label': 'French'},
                          {'value': 'de', 'label': 'German'},
                          {'value': 'it', 'label': 'Italian'},
                          {'value': 'pt', 'label': 'Portuguese'},
                          {'value': 'ru', 'label': 'Russian'},
                          {'value': 'zh', 'label': 'Chinese'},
                          {'value': 'ja', 'label': 'Japanese'},
                          {'value': 'ar', 'label': 'Arabic'},
                        ],
                        (value) => setState(() => _selectedLanguage = value),
                      ),
                      _buildSwitchSetting(
                        'Include Metadata',
                        'Show translation details and statistics',
                        _includeMetadata,
                        (value) => setState(() => _includeMetadata = value),
                      ),
                      _buildSwitchSetting(
                        'Format Output',
                        'Apply formatting to translated text',
                        _formatOutput,
                        (value) => setState(() => _formatOutput = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // App Preferences
                  _buildSectionCard(
                    title: 'App Preferences',
                    icon: Icons.settings,
                    children: [
                      _buildDropdownSetting(
                        'Theme',
                        _selectedTheme,
                        [
                          {'value': 'light', 'label': 'Light'},
                          {'value': 'dark', 'label': 'Dark'},
                          {'value': 'system', 'label': 'System Default'},
                        ],
                        (value) => setState(() => _selectedTheme = value),
                      ),
                      _buildSwitchSetting(
                        'Notifications',
                        'Enable app notifications',
                        _notificationsEnabled,
                        (value) =>
                            setState(() => _notificationsEnabled = value),
                      ),
                      _buildSwitchSetting(
                        'Auto-save Translations',
                        'Automatically save translations to history',
                        _autoSaveTranslations,
                        (value) =>
                            setState(() => _autoSaveTranslations = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Data Management
                  _buildSectionCard(
                    title: 'Data Management',
                    icon: Icons.storage,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cloud_download),
                        title: const Text('Export Translation History'),
                        subtitle:
                            const Text('Download your translations as CSV'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(context, '/translation-history');
                        },
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.delete_sweep, color: Colors.red),
                        title: const Text('Clear Translation History'),
                        subtitle: const Text('Delete all saved translations'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _showClearHistoryDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account Settings
                  _buildSectionCard(
                    title: 'Account',
                    icon: Icons.account_circle,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Profile'),
                        subtitle: const Text('Manage your profile information'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Change Password'),
                        subtitle: const Text('Update your account password'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Settings',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String currentValue,
    List<Map<String, String>> options,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: currentValue,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _showClearHistoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Translation History'),
        content: const Text(
          'Are you sure you want to delete all your saved translations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == true) {
      // TODO: Implement clear history functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feature coming soon'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
