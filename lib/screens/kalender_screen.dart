import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DeadlineEvent {
  final String title;
  final String type;
  final String description;
  final DateTime deadline;

  DeadlineEvent({
    required this.title,
    required this.type,
    required this.description,
    required this.deadline,
  });
}

class KalenderScreen extends StatefulWidget {
  const KalenderScreen({super.key});

  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen> {
  late Map<DateTime, List<DeadlineEvent>> _events;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedDay = _focusedDay;
    _fetchDeadlines();
  }

  Future<void> _fetchDeadlines() async {
    try {
      final supabase = Supabase.instance.client;

      final List<dynamic> kuisData = await supabase
          .from('kuis')
          .select('judul, deskripsi, deadline');

      final List<dynamic> tugasData = await supabase
          .from('tugas')
          .select('judul, deskripsi, deadline');

      final Map<DateTime, List<DeadlineEvent>> loadedEvents = {};

      void addEvent(String type, dynamic item) {
        if (item['deadline'] != null) {
          final date = DateTime.parse(item['deadline']).toLocal();
          final dateKey = DateTime.utc(date.year, date.month, date.day);

          final event = DeadlineEvent(
            title: item['judul'] ?? 'Tanpa Judul',
            type: type,
            description: item['deskripsi'] ?? '-',
            deadline: date,
          );

          if (loadedEvents[dateKey] == null) {
            loadedEvents[dateKey] = [];
          }
          loadedEvents[dateKey]!.add(event);
        }
      }

      // Proses data Kuis
      for (var item in kuisData) {
        addEvent('Kuis', item);
      }

      // Proses data Tugas
      for (var item in tugasData) {
        addEvent('Tugas', item);
      }

      setState(() {
        _events = loadedEvents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching deadlines: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi helper untuk mengambil event berdasarkan hari
  List<DeadlineEvent> _getEventsForDay(DateTime day) {
    // Pastikan key menggunakan UTC midnight yang sama dengan saat generate map
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // Ambil event untuk hari yang sedang dipilih untuk ditampilkan di list bawah
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Kalender Akademik',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
        ),
      ),
      body: Column(
        children: [
          // Card Kalender
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TableCalendar<DeadlineEvent>(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,

                // 3. Integrasi Event Loader (Ini yang memunculkan titik/marker)
                eventLoader: _getEventsForDay,

                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() => _calendarFormat = format);
                  }
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,

                // Styling Marker (Titik penanda deadline)
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible:
                      false, // Menyembunyikan tombol format agar lebih rapi
                  titleCentered: true,
                ),
              ),
            ),
          ),

          // Info Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deadline Hari Ini',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedEvents.isEmpty
                            ? 'Tidak ada deadline'
                            : '${selectedEvents.length} Kegiatan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // List Deadline
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada deadline di tanggal ini',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      final isKuis = event.type == 'Kuis';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: isKuis ? Colors.orange : Colors.purple,
                              width: 5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                event.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('HH:mm').format(event.deadline),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isKuis
                                          ? Colors.orange.shade50
                                          : Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      event.type,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isKuis
                                            ? Colors.orange.shade700
                                            : Colors.purple.shade700,
                                      ),
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
          ),
        ],
      ),
    );
  }
}
