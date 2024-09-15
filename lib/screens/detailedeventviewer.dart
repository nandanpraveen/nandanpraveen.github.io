import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outreachapp/presetobjects.dart';
import 'package:outreachapp/screens/allscreenscontainer.dart';

class DetailedEventViewer extends StatefulWidget {
  const DetailedEventViewer({
    super.key,
    required this.eventName,
    required this.eventInfo,
    required this.maxMembers,
    required this.currentMembers,
    required this.eventDate,
    required this.eventStart,
    required this.eventFinish,
    required this.attendees,
    required this.emails,
    required this.isAdmin,
  });

  final String eventName;
  final String eventInfo;
  final double maxMembers;
  final int currentMembers;
  final DateTime? eventDate;
  final TimeOfDay? eventStart;
  final TimeOfDay? eventFinish;
  final List<String> attendees;
  final List<String> emails;
  final bool isAdmin;

  @override
  State<DetailedEventViewer> createState() => _DetailedEventViewerState();
}

class _DetailedEventViewerState extends State<DetailedEventViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("View Event"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        backgroundColor: Colors.black,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AllScreensContainer(),
              ),
            );
          },
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.eventName,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18.0,
                      right: 18.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${widget.eventStart!.hour}:${timeFixer(widget.eventStart!.minute)} to ${widget.eventFinish!.hour}:${timeFixer(widget.eventFinish!.minute)}",
                        ),
                        Text(
                            "${widget.eventDate!.month}/${widget.eventDate!.day}/${widget.eventDate!.year}")
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  Text(widget.eventInfo),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "${widget.maxMembers.toInt().toString()} members required"),
                      Text(
                          "${widget.attendees.length.toString()} spot(s) taken"),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: widget.attendees.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4.0), // Adds some spacing between cards
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(
                                  height: 2,
                                  width: 8,
                                ),
                                Text(
                                  widget.attendees[index],
                                  style: const TextStyle(
                                      fontSize:
                                          16), // Adjusts the text size as needed
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.green),
                        foregroundColor: WidgetStatePropertyAll(Colors.white),
                      ),
                      child: const Text("Get event emails"),
                      onPressed: () {
                        if (widget.isAdmin) {
                          Clipboard.setData(
                              ClipboardData(text: widget.emails.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Copied to clipboard")));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Sorry, you need to be an admin for this."),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
