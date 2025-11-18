import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() {
  runApp(const NightShiftApp());
}

class NightShiftApp extends StatelessWidget {
  const NightShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Night Shift Companion',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF111827),
        cardColor: const Color(0xFF1F2937),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ShiftScheduleScreen(),
    BreakTimerScreen(),
    SleepTrackerScreen(),
    ContactListScreen(),
    HealthTipsScreen(),
    QuickNotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌙 Night Shift Companion'),
        backgroundColor: const Color(0xFF1F2937),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF1F2937),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.nightlight), label: 'Sleep'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
        ],
      ),
    );
  }
}

// SHIFT SCHEDULE SCREEN
class ShiftScheduleScreen extends StatefulWidget {
  const ShiftScheduleScreen({super.key});

  @override
  State<ShiftScheduleScreen> createState() => _ShiftScheduleScreenState();
}

class _ShiftScheduleScreenState extends State<ShiftScheduleScreen> {
  List<Map<String, dynamic>> shifts = [];
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  @override
  void dispose() {
    dateController.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  Future<void> _loadShifts() async {
    final prefs = await SharedPreferences.getInstance();
    final shiftsJson = prefs.getString('shifts');
    if (shiftsJson != null) {
      setState(() {
        shifts = List<Map<String, dynamic>>.from(json.decode(shiftsJson));
      });
    }
  }

  Future<void> _saveShifts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shifts', json.encode(shifts));
  }

  void _addShift() {
    if (dateController.text.isNotEmpty &&
        startController.text.isNotEmpty &&
        endController.text.isNotEmpty) {
      setState(() {
        shifts.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'date': dateController.text,
          'startTime': startController.text,
          'endTime': endController.text,
        });
      });
      _saveShifts();
      dateController.clear();
      startController.clear();
      endController.clear();
    }
  }

  void _deleteShift(int id) {
    setState(() {
      shifts.removeWhere((shift) => shift['id'] == id);
    });
    _saveShifts();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Shift Schedule',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startController,
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endController,
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addShift,
                    child: const Text('Add Shift'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...shifts.map(
          (shift) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(shift['date'].toString()),
              subtitle: Text('${shift['startTime']} - ${shift['endTime']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteShift(shift['id'] as int),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// BREAK TIMER SCREEN
class BreakTimerScreen extends StatefulWidget {
  const BreakTimerScreen({super.key});

  @override
  State<BreakTimerScreen> createState() => _BreakTimerScreenState();
}

class _BreakTimerScreenState extends State<BreakTimerScreen> {
  int minutes = 15;
  int seconds = 0;
  bool isActive = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (seconds == 0) {
          if (minutes == 0) {
            isActive = false;
            timer.cancel();
            _showAlert();
          } else {
            minutes--;
            seconds = 59;
          }
        } else {
          seconds--;
        }
      });
    });
  }

  void _showAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Break Time Over!'),
        content: const Text('Your break time has ended.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => isActive = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      isActive = false;
      minutes = 15;
      seconds = 0;
    });
  }

  void _setMinutes(int mins) {
    _timer?.cancel();
    setState(() {
      isActive = false;
      minutes = mins;
      seconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Break Timer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: isActive ? _pauseTimer : _startTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text(isActive ? 'Pause' : 'Start'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _resetTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => _setMinutes(5),
                          child: const Text('5 min'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _setMinutes(15),
                          child: const Text('15 min'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _setMinutes(30),
                          child: const Text('30 min'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SLEEP TRACKER SCREEN
class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  List<Map<String, dynamic>> logs = [];
  final TextEditingController dateController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  String quality = 'good';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    dateController.dispose();
    hoursController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString('sleepLogs');
    if (logsJson != null) {
      setState(() {
        logs = List<Map<String, dynamic>>.from(json.decode(logsJson));
      });
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sleepLogs', json.encode(logs));
  }

  void _addLog() {
    if (dateController.text.isNotEmpty && hoursController.text.isNotEmpty) {
      setState(() {
        logs.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'date': dateController.text,
          'hours': hoursController.text,
          'quality': quality,
        });
      });
      _saveLogs();
      dateController.clear();
      hoursController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sleep Tracker',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hours Slept',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: quality,
                  decoration: const InputDecoration(
                    labelText: 'Sleep Quality',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'excellent',
                      child: Text('Excellent'),
                    ),
                    DropdownMenuItem(value: 'good', child: Text('Good')),
                    DropdownMenuItem(value: 'fair', child: Text('Fair')),
                    DropdownMenuItem(value: 'poor', child: Text('Poor')),
                  ],
                  onChanged: (value) => setState(() => quality = value!),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addLog,
                    child: const Text('Log Sleep'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...logs.map(
          (log) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(log['date'].toString()),
              subtitle: Text('${log['hours']} hours - ${log['quality']}'),
            ),
          ),
        ),
      ],
    );
  }
}

// CONTACT LIST SCREEN
class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<Map<String, dynamic>> contacts = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController replyMsgController = TextEditingController();
  bool autoReply = false;
  String replyMsg = 'Please call me later';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    replyMsgController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      setState(() {
        contacts = List<Map<String, dynamic>>.from(json.decode(contactsJson));
      });
    }
    setState(() {
      autoReply = prefs.getBool('autoReply') ?? false;
      replyMsg = prefs.getString('replyMsg') ?? 'Please call me later';
      replyMsgController.text = replyMsg;
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contacts', json.encode(contacts));
    await prefs.setBool('autoReply', autoReply);
    await prefs.setString('replyMsg', replyMsg);
  }

  void _addContact() {
    if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
      setState(() {
        contacts.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'name': nameController.text,
          'phone': phoneController.text,
          'favorite': false,
        });
      });
      _saveContacts();
      nameController.clear();
      phoneController.clear();
    }
  }

  void _toggleFavorite(int id) {
    setState(() {
      final index = contacts.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        contacts[index]['favorite'] = !contacts[index]['favorite'];
      }
    });
    _saveContacts();
  }

  void _deleteContact(int id) {
    setState(() {
      contacts.removeWhere((c) => c['id'] == id);
    });
    _saveContacts();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedContacts = List<Map<String, dynamic>>.from(
      contacts,
    )..sort((a, b) => (b['favorite'] ? 1 : 0).compareTo(a['favorite'] ? 1 : 0));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Contacts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Auto-Reply for Non-Favorites'),
                    Switch(
                      value: autoReply,
                      onChanged: (value) {
                        setState(() => autoReply = value);
                        _saveContacts();
                      },
                    ),
                  ],
                ),
                if (autoReply) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: replyMsgController,
                    onChanged: (value) {
                      replyMsg = value;
                      _saveContacts();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Auto-reply message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addContact,
                    child: const Text('Add Contact'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...sortedContacts.map(
          (contact) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: contact['favorite'] == true ? const Color(0xFF2D3748) : null,
            child: ListTile(
              title: Text(contact['name'].toString()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact['phone'].toString()),
                  Text(
                    contact['favorite'] == true
                        ? '⭐ Can call during sleep'
                        : '🌙 Do Not Disturb during sleep',
                    style: TextStyle(
                      fontSize: 12,
                      color: contact['favorite'] == true
                          ? Colors.yellow
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      contact['favorite'] == true
                          ? Icons.star
                          : Icons.star_border,
                      color: contact['favorite'] == true
                          ? Colors.yellow
                          : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(contact['id'] as int),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () => _makeCall(contact['phone'].toString()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteContact(contact['id'] as int),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// HEALTH TIPS SCREEN
class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Health Tips',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          '💧',
          'Stay Hydrated',
          'Drink water regularly throughout your shift to stay alert and healthy.',
        ),
        _buildTipCard(
          '🥗',
          'Healthy Snacks',
          'Choose fruits, nuts, and yogurt over sugary snacks for sustained energy.',
        ),
        _buildTipCard(
          '🚶',
          'Take Walks',
          'Walk for 5-10 minutes every hour to boost circulation and reduce fatigue.',
        ),
        _buildTipCard(
          '☀️',
          'Morning Sunlight',
          'Get 15-30 minutes of sunlight after your shift to regulate your circadian rhythm.',
        ),
        _buildTipCard(
          '☕',
          'Limit Caffeine',
          'Avoid caffeine 4-6 hours before your planned sleep time.',
        ),
        _buildTipCard(
          '🏥',
          'Regular Checkups',
          'Schedule regular health checkups as night shift work can affect your health.',
        ),
        const SizedBox(height: 24),
        const Text(
          'Sleep Tips',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          '🌑',
          'Dark Environment',
          'Use blackout curtains or eye masks to block out daylight completely.',
        ),
        _buildTipCard(
          '❄️',
          'Cool Temperature',
          'Keep your bedroom between 60-67°F (15-19°C) for optimal sleep.',
        ),
        _buildTipCard(
          '⏰',
          'Consistent Routine',
          'Go to bed and wake up at the same times every day, even on days off.',
        ),
        _buildTipCard(
          '📱',
          'Screen-Free Time',
          'Avoid screens 30-60 minutes before bed - blue light disrupts melatonin.',
        ),
        _buildTipCard(
          '🔊',
          'White Noise',
          'Use white noise, earplugs, or a fan to block daytime sounds.',
        ),
        _buildTipCard(
          '🧘',
          'Relaxation Techniques',
          'Try deep breathing, meditation, or gentle stretching before sleep.',
        ),
        const SizedBox(height: 24),
        const Text(
          'Sleep Music',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        _buildMusicCard(
          'Ocean Waves',
          '60 min',
          'https://www.youtube.com/watch?v=V1PtqHkc14w',
        ),
        _buildMusicCard(
          'Rain Sounds',
          '45 min',
          'https://www.youtube.com/watch?v=mPZkdNFkNps',
        ),
        _buildMusicCard(
          'Delta Waves Sleep Music',
          '8 hours',
          'https://www.youtube.com/watch?v=1ZYbU82GVz4',
        ),
        _buildMusicCard(
          'Piano Sleep Music',
          '3 hours',
          'https://www.youtube.com/watch?v=aEq16aZd3DE',
        ),
        _buildMusicCard(
          'Nature Sounds',
          '2 hours',
          'https://www.youtube.com/watch?v=bP9gMpl1gyQ',
        ),
        _buildMusicCard(
          'Meditation Music',
          '4 hours',
          'https://www.youtube.com/watch?v=lFcSrYw-ARY',
        ),
      ],
    );
  }

  Widget _buildTipCard(String emoji, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicCard(String title, String duration, String url) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.music_note, color: Colors.green),
        title: Text(title),
        subtitle: Text(duration),
        trailing: const Icon(Icons.play_arrow, color: Colors.blue),
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}

// QUICK NOTES SCREEN
class QuickNotesScreen extends StatefulWidget {
  const QuickNotesScreen({super.key});

  @override
  State<QuickNotesScreen> createState() => _QuickNotesScreenState();
}

class _QuickNotesScreenState extends State<QuickNotesScreen> {
  List<Map<String, dynamic>> notes = [];
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('notes');
    if (notesJson != null) {
      setState(() {
        notes = List<Map<String, dynamic>>.from(json.decode(notesJson));
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', json.encode(notes));
  }

  void _addNote() {
    if (noteController.text.trim().isNotEmpty) {
      setState(() {
        notes.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'text': noteController.text,
          'date': DateTime.now().toString(),
        });
      });
      _saveNotes();
      noteController.clear();
    }
  }

  void _deleteNote(int id) {
    setState(() {
      notes.removeWhere((note) => note['id'] == id);
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Quick Notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Write a note...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addNote,
                    child: const Text('Add Note'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...notes.map(
          (note) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note['date'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteNote(note['id'] as int),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(note['text'].toString()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
