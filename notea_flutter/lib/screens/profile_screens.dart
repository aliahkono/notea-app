import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../services/database_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'pet_screens.dart';

/// Profile & settings (10 Profile & Settings in the redesign).
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  Future<void> _editName(BuildContext context, ProfileController p) async {
    final c = TextEditingController(text: p.userProfile.username);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Your name', style: NText.title),
        content: TextField(controller: c, autofocus: true, decoration: nInput('Name', fill: NC.sand)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) p.updateUsername(name);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final pet = context.watch<PetController>();
    final notes = context.watch<NotesController>().getNotesCount();
    final journals = context.watch<JournalController>().journals.length;
    final db = context.watch<DatabaseManager>();
    final theme = context.watch<ThemeManager>().selectedTheme;
    final u = profile.userProfile;
    final focusHours = pet.totalFocusMinutes / 60;

    final achievements = [
      (Icons.local_fire_department_rounded, Accent.peach, '3-day streak', pet.streak >= 3),
      (Icons.timer_rounded, Accent.sky, 'First focus', pet.state.totalFocusSessions >= 1),
      (Icons.edit_note_rounded, Accent.mint, '5 notes', notes >= 5),
      (Icons.auto_stories_rounded, Accent.butter, '3 journals', journals >= 3),
      (Icons.pets_rounded, Accent.pink, 'Hatched a pet', pet.state.hatched),
      (Icons.emoji_events_rounded, Accent.plum, 'Level 5', pet.state.level >= 5),
    ];
    final unlocked = achievements.where((a) => a.$4).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(label: 'Back'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  NCard(
                    radius: 26,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => pushPage(context, const AvatarCustomizationView(), fullscreenDialog: true),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(color: NC.pinkSoft, shape: BoxShape.circle),
                            clipBehavior: Clip.antiAlias,
                            child: u.avatarImage != null
                                ? Image.memory(u.avatarImage!, fit: BoxFit.cover)
                                : Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: pet.state.hatched
                                        ? PetImage(companion: pet.companion)
                                        : Image.asset('assets/pet/egg_nest.png'),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.username, style: NText.title, overflow: TextOverflow.ellipsis),
                              Text(
                                  'Member since ${u.dateCreated.year}${pet.state.hatched ? ' · Lv ${pet.state.level}' : ''}',
                                  style: NText.caption),
                            ],
                          ),
                        ),
                        CircleIconButton(Icons.edit_rounded,
                            size: 40, iconSize: 20, background: NC.sand, shadow: false,
                            onTap: () => _editName(context, profile)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MiniStat(focusHours >= 10 ? '${focusHours.round()}h' : '${focusHours.toStringAsFixed(1)}h', 'Focused', Accent.sky),
                      const SizedBox(width: 10),
                      _MiniStat('$notes', 'Notes', Accent.butter),
                      const SizedBox(width: 10),
                      _MiniStat('${pet.streak}', 'Day streak', Accent.peach),
                    ],
                  ),
                  const SizedBox(height: 14),
                  NCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('Achievements', style: NText.headline)),
                            Text('$unlocked / ${achievements.length}', style: NText.caption),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: achievements
                              .map((a) => Tooltip(
                                    message: a.$3,
                                    child: Opacity(
                                      opacity: a.$4 ? 1 : 0.4,
                                      child: IconBubble(a.$1, a.$4 ? a.$2 : const Accent(NC.muted, NC.sand),
                                          size: 48, iconSize: 26, radius: 16),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  NCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _SettingTile(Icons.palette_rounded, Accent.plum, 'Theme', theme.rawValue,
                            () => pushPage(context, const ThemePickerView(), fullscreenDialog: true)),
                        _SettingTile(Icons.pets_rounded, Accent.pink, 'Pet settings',
                            pet.state.hatched ? pet.state.name : 'Egg', () {
                          if (pet.state.hatched) {
                            pushPage(context, const CompanionsPage());
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Hatch your egg first — finish a focus session!')));
                          }
                        }),
                        _SettingTile(Icons.notifications_rounded, Accent.peach, 'Reminders', 'Soon',
                            () => pushPage(context, const ComingSoonPage(name: 'Reminders'))),
                        _SettingTile(Icons.cloud_rounded, Accent.mint, 'Backup & sync', 'On device',
                            () => pushPage(context, const ComingSoonPage(name: 'Backup & sync'))),
                        _SettingTile(Icons.person_rounded, Accent.sky, 'Account',
                            db.isSignedIn ? db.currentUser!.email : 'Sign in', () {
                          if (db.isSignedIn) {
                            _confirmSignOut(context, db);
                          } else {
                            showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => const AuthScreen());
                          }
                        }),
                        _SettingTile(Icons.info_rounded, Accent.butter, 'About Notea', 'v2.0',
                            () => showAboutDialog(
                                  context: context,
                                  applicationName: 'Notea',
                                  applicationVersion: '2.0 (Flutter)',
                                  applicationLegalese: 'A cozy study app with a pet that grows with you.',
                                )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/pet/peek_cat.png', height: 54),
                        const SizedBox(height: 6),
                        const Text('Keep shining — you\'re doing great!', style: NText.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, DatabaseManager db) async {
    final ok = await confirmDialog(context,
        title: 'Sign out?', message: 'Your notes stay on this phone.', confirm: 'Sign out');
    if (ok) db.signOut();
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Accent accent;
  const _MiniStat(this.value, this.label, this.accent);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: NCard(
        color: accent.soft,
        shadow: false,
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: NText.title),
            Text(label, style: NText.caption),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Accent accent;
  final String title;
  final String value;
  final VoidCallback onTap;
  const _SettingTile(this.icon, this.accent, this.title, this.value, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconBubble(icon, accent, size: 36, iconSize: 20, radius: 12),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: NText.body)),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(value, overflow: TextOverflow.ellipsis, style: NText.caption),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: NC.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------
class AvatarCustomizationView extends StatefulWidget {
  const AvatarCustomizationView({super.key});

  @override
  State<AvatarCustomizationView> createState() => _AvatarCustomizationViewState();
}

class _AvatarCustomizationViewState extends State<AvatarCustomizationView> {
  Uint8List? selectedImage;

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => selectedImage = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<ProfileController>().userProfile.avatarImage;
    final shown = selectedImage ?? current;
    return SheetScaffold(
      title: 'Profile photo',
      leadingLabel: 'Back',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: NC.pinkSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: NC.surface, width: 5),
                  boxShadow: softShadow(),
                ),
                clipBehavior: Clip.antiAlias,
                child: shown != null
                    ? Image.memory(shown, fit: BoxFit.cover)
                    : const Icon(Icons.person_rounded, size: 80, color: NC.pink),
              ),
              const SizedBox(height: 24),
              NButton('Choose from gallery', icon: Icons.photo_library_rounded, onPressed: _pick),
              const SizedBox(height: 12),
              if (selectedImage != null)
                NButton('Save photo', icon: Icons.check_rounded, style: NButtonStyle.soft, onPressed: () {
                  context.read<ProfileController>().updateAvatarImage(selectedImage);
                  Navigator.of(context).pop();
                }),
              if (selectedImage == null && current != null)
                NButton('Remove photo', icon: Icons.delete_rounded, style: NButtonStyle.light, onPressed: () {
                  context.read<ProfileController>().updateAvatarImage(null);
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme picker
// ---------------------------------------------------------------------------
class ThemePickerView extends StatelessWidget {
  const ThemePickerView({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ThemeManager>().selectedTheme;
    return SheetScaffold(
      title: 'Theme',
      leadingLabel: 'Back',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: AppTheme.values.map((t) {
          final on = t == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                context.read<ProfileController>().updateTheme(t);
                context.read<ThemeManager>().apply(t);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: on ? t.primary : NC.line, width: on ? 2.5 : 1.5),
                ),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: t.primarySoft, shape: BoxShape.circle)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(t.rawValue, style: NText.headline)),
                    if (on) Icon(Icons.check_circle_rounded, color: t.primary),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
