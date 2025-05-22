import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:tikitar_demo/features/auth/meetings_controller.dart';

class UserMeetings extends StatefulWidget {
  final int userId;
  final String userName;

  const UserMeetings({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserMeetings> createState() => _UserMeetingsState();
}

class _UserMeetingsState extends State<UserMeetings> {
  List<dynamic> allMeetings = [];
  List<dynamic> filteredMeetings = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMeetings();
  }

  Future<void> fetchMeetings() async {
    try {
      final meetingsList = await MeetingsController.userBasedMeetings(widget.userId);
      allMeetings = meetingsList;

      // Set default date range to the full available period
      if (allMeetings.isNotEmpty) {
        final dates = allMeetings.map((m) {
          final rawDate = m['meeting_date'] ?? m['date'];
          try {
            return DateTime.parse(rawDate);
          } catch (_) {
            return null;
          }
        }).whereType<DateTime>().toList();

        dates.sort();
        if (dates.isNotEmpty) {
          startDate = dates.first;
          endDate = dates.last;
        }
      }

      applyFilter();
      setState(() => isLoading = false);
    } catch (e) {
      developer.log("Failed to fetch meetings: $e");
      setState(() => isLoading = false);
    }
  }

  void applyFilter() {
    if (startDate == null || endDate == null) {
      filteredMeetings = allMeetings;
      return;
    }

    filteredMeetings = allMeetings.where((meeting) {
      final rawDate = meeting['meeting_date'] ?? meeting['date'];
      if (rawDate == null) return false;
      try {
        final parsedDate = DateTime.parse(rawDate);
        return parsedDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
               parsedDate.isBefore(endDate!.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  String twoDigits(int n) => n < 10 ? '0$n' : '$n';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: (startDate != null && endDate != null)
                          ? DateTimeRange(start: startDate!, end: endDate!)
                          : null,
                    );

                    if (picked != null) {
                      setState(() {
                        startDate = picked.start;
                        endDate = picked.end;
                        applyFilter();
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: const Text("Select Date Range"),
                ),
                const SizedBox(width: 12),
                if (startDate != null && endDate != null)
                  Expanded(
                    child: Text(
                      "${twoDigits(startDate!.day)}-${twoDigits(startDate!.month)}-${startDate!.year} → "
                      "${twoDigits(endDate!.day)}-${twoDigits(endDate!.month)}-${endDate!.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          isLoading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: filteredMeetings.isEmpty
                      ? const Center(child: Text("No meetings found"))
                      : ListView.builder(
                          itemCount: filteredMeetings.length,
                          itemBuilder: (context, index) {
                            final meeting = filteredMeetings[index];
                            final rawDate = meeting['meeting_date'] ?? meeting['date'];
                            String formattedDate = 'Unknown';
                            try {
                              final parsedDate = DateTime.parse(rawDate);
                              formattedDate =
                                  "${parsedDate.year}-${twoDigits(parsedDate.month)}-${twoDigits(parsedDate.day)}";
                            } catch (e) {
                              formattedDate = rawDate ?? 'Invalid';
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: Text("Meeting on $formattedDate"),
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
