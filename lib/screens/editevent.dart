// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:outreachapp/presetobjects.dart';
import 'package:outreachapp/screens/alleventspage.dart';
import 'package:outreachapp/screens/allscreenscontainer.dart';

class EventEditor extends StatefulWidget {
  const EventEditor({
    super.key,
    required this.eventName,
    required this.eventInfo,
    required this.maxMembers,
    required this.currentMembers,
    required this.eventDate,
    required this.eventStart,
    required this.eventFinish,
    required this.attendees,
    required this.id,
    required this.emails,
  });

  final String eventName;
  final String eventInfo;
  final double maxMembers;
  final int currentMembers;
  final DateTime? eventDate;
  final TimeOfDay? eventStart;
  final TimeOfDay? eventFinish;
  final List<String> attendees;
  final String id;
  final List<String> emails;

  @override
  State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  @override
  Widget build(BuildContext context) {
    TextEditingController editedEventName = TextEditingController(
      text: widget.eventName,
    );
    TextEditingController editedEventInfo = TextEditingController(
      text: widget.eventInfo,
    );
    DateTime editedEventDate = widget.eventDate!;
    TimeOfDay editedEventStart = widget.eventStart!;
    TimeOfDay editedEventFinish = widget.eventFinish!;
    double editedMaxMembers = widget.maxMembers;
    final List<String> editedEmails = widget.emails;
    // ignore: unused_local_variable
    List<String> editedAttendees = widget.attendees;
    Color userChosenAccent = Colors.green;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Edit Event"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        backgroundColor: Colors.black,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AllEventsPage()),
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
                  TextFormField(
                    controller: editedEventName,
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
                        TextButton(
                          style: const ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(Colors.transparent),
                              foregroundColor:
                                  WidgetStatePropertyAll(Colors.white)),
                          child: Text(
                              "${widget.eventStart!.hour}:${timeFixer(widget.eventStart!.minute)} to ${widget.eventFinish!.hour}:${timeFixer(widget.eventFinish!.minute)}"),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text(
                                      "Change Event Start or Event End?"),
                                  actions: [
                                    TextButton(
                                        style: const ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.transparent),
                                            foregroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.white)),
                                        onPressed: () async {
                                          editedEventStart =
                                              await showTimePicker(
                                                      context: context,
                                                      initialTime:
                                                          TimeOfDay.now())
                                                  as TimeOfDay;
                                        },
                                        child: const Text("Start")),
                                    TextButton(
                                        style: const ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.transparent),
                                            foregroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.white)),
                                        onPressed: () async {
                                          editedEventFinish =
                                              await showTimePicker(
                                                      context: context,
                                                      initialTime:
                                                          TimeOfDay.now())
                                                  as TimeOfDay;
                                        },
                                        child: const Text("End")),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        TextButton(
                          style: const ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(Colors.transparent),
                              foregroundColor:
                                  WidgetStatePropertyAll(Colors.white)),
                          child: Text(
                              "${widget.eventDate!.month}/${widget.eventDate!.day}/${widget.eventDate!.year}"),
                          onPressed: () async {
                            editedEventDate = (await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 1000))))!;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  TextFormField(
                    controller: editedEventInfo,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: const ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(Colors.transparent),
                          foregroundColor:
                              WidgetStatePropertyAll(Colors.white)),
                      onPressed: () async {
                        editedMaxMembers = await showDialog<double>(
                              context: context,
                              builder: (context) {
                                double tempMaxMembers = widget
                                    .maxMembers; // Temporary variable to hold the slider value
                                return AlertDialog(
                                  surfaceTintColor: userChosenAccent,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  title: const Center(
                                    child: Text(
                                        "How many members can be at this event?"),
                                  ),
                                  content: StatefulBuilder(
                                    builder: (context, setState) {
                                      return Container(
                                        constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.3),
                                        child: Slider(
                                          activeColor: Colors.red,
                                          inactiveColor: Colors.red.shade900,
                                          max: 100,
                                          divisions: 100,
                                          label:
                                              tempMaxMembers.round().toString(),
                                          value: tempMaxMembers,
                                          onChanged: (double value) {
                                            setState(() {
                                              tempMaxMembers = value;
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      style: ButtonStyle(
                                        overlayColor: WidgetStateProperty.all(
                                            userChosenAccent.withOpacity(0.3)),
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                                Colors.transparent),
                                        foregroundColor:
                                            WidgetStateProperty.all(
                                                userChosenAccent),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context,
                                            tempMaxMembers); // Return the selected value
                                      },
                                      child: const Text("Submit"),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            widget.maxMembers;
                      },
                      child: Text(
                          "${widget.maxMembers.toInt().toString()} attendees"),
                    ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person),
                                    const SizedBox(
                                      height: 2,
                                      width: 8,
                                    ),
                                    Text(
                                      editedAttendees[index],
                                      style: const TextStyle(
                                          fontSize:
                                              16), // Adjusts the text size as needed
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () async {
                                    String attendeeFullNameToRemove =
                                        editedAttendees[index];
                                    List<String> updatedAttendeesList =
                                        List.from(widget.attendees);
                                    updatedAttendeesList
                                        .remove(attendeeFullNameToRemove);

                                    String emailToRemove = editedEmails[index];
                                    List<String> updatedEmailsList =
                                        List.from(widget.emails);
                                    updatedEmailsList.remove(emailToRemove);

                                    if (updatedAttendeesList.isEmpty) {
                                      updatedAttendeesList.add("");
                                    }

                                    // Update the event document in Firestore
                                    await FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(widget.id)
                                        .update({
                                      'attendees': updatedAttendeesList,
                                    });

                                    await FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(widget.id)
                                        .update({
                                      'emails': updatedEmailsList,
                                    });

                                    // Find the user by their full name
                                    QuerySnapshot querySnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .where('firstName',
                                                isEqualTo:
                                                    attendeeFullNameToRemove
                                                        .split(' ')[0])
                                            .where('lastName',
                                                isEqualTo:
                                                    attendeeFullNameToRemove
                                                        .split(' ')[1])
                                            .get();

                                    if (querySnapshot.docs.isNotEmpty) {
                                      DocumentSnapshot userDoc =
                                          querySnapshot.docs.first;
                                      List<dynamic> currentUserEvents =
                                          List<dynamic>.from(
                                              userDoc['events'] ?? []);

                                      // Validate that the event ID exists in the user's events array
                                      if (currentUserEvents
                                          .contains(widget.id)) {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userDoc.id)
                                              .update({
                                            'events': FieldValue.arrayRemove(
                                                [widget.id]),
                                          });
                                          debugPrint(
                                              "Event ID removed successfully from user's events list.");
                                        } catch (e) {
                                          debugPrint(
                                              "Error removing event ID from user's events list: $e");
                                        }
                                      } else {
                                        debugPrint(
                                            "Event ID does not exist in the user's events list.");
                                      }
                                    } else {
                                      debugPrint("User document not found.");
                                    }

                                    // Update the state to reflect the changes in the UI
                                    setState(() {
                                      editedAttendees.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      String name = editedEventName.text;
                      String info = editedEventInfo.text;

                      Map<String, dynamic> eventMap = {
                        'eventName': name,
                        'eventInfo': info,
                        'maxMembers': editedMaxMembers,
                        'currentMembers': widget.currentMembers,
                        'eventDate': editedEventDate.toIso8601String(),
                        'eventStart':
                            '${editedEventStart.hour}:${timeFixer(editedEventStart.minute)}',
                        'eventFinish':
                            '${editedEventFinish.hour}:${timeFixer(editedEventFinish.minute)}',
                        'attendees': widget.attendees,
                        'id': widget.id,
                      };

                      try {
                        // Update the document in Firestore
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(widget.id)
                            .set(eventMap);

                        // Navigate back to the previous screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AllScreensContainer()),
                        );
                      } catch (e) {
                        debugPrint("Error caught: $e");
                      }

                      // Optionally, show a success message
                    },
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.green),
                        foregroundColor: WidgetStatePropertyAll(Colors.white)),
                    child: const Text("Confirm Edits"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
