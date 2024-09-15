// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outreachapp/presetobjects.dart';
import 'package:outreachapp/screens/detailedeventviewer.dart';
import 'package:outreachapp/screens/editevent.dart';

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({super.key});

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class EventCard extends StatelessWidget {
  final Event event;

  // ignore: use_key_in_widget_constructors
  const EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailedEventViewer(
              eventName: event.eventName,
              eventInfo: event.eventInfo,
              maxMembers: event.maxMembers,
              currentMembers: event.currentMembers,
              eventDate: event.eventDate,
              eventStart: event.eventStart,
              eventFinish: event.eventFinish,
              attendees: event.attendees,
              emails: event.emails,
              isAdmin: currentUser.isAdmin,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.red.shade700,
        margin: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity - 20,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${event.eventName.substring(0, min(event.eventName.length, 15))}..",
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () {
                              if (currentUser.isAdmin) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EventEditor(
                                      eventName: event.eventName,
                                      eventInfo: event.eventInfo,
                                      maxMembers: event.maxMembers,
                                      eventDate: event.eventDate,
                                      currentMembers: event.currentMembers,
                                      eventFinish: event.eventFinish,
                                      eventStart: event.eventStart,
                                      attendees: event.attendees,
                                      id: event.id,
                                      emails: event.emails,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.edit)),
                        IconButton(
                          onPressed: () {
                            if (currentUser.isAdmin) {
                              if (event.attendees.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      surfaceTintColor: Colors.red,
                                      backgroundColor:
                                          Theme.of(context).colorScheme.surface,
                                      title: const Text(
                                          'Remove all attendees first.'),
                                      content: const Text(
                                          'In order to continue with this action, please manually remove all the attendees of event. This can be done by navigating to the editing screen.'),
                                      actions: <Widget>[
                                        TextButton(
                                          style: const ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.red),
                                            foregroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.white),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event.id)
                                    .delete();
                              }
                            }
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  "From ${event.eventStart!.hour}:${timeFixer(event.eventStart!.minute)} to ${event.eventFinish!.hour}:${timeFixer(event.eventFinish!.minute)} on ${event.eventDate!.month}/${event.eventDate!.day}/${event.eventDate!.year}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8.0),
                Text(
                    "${event.eventInfo.substring(0, (event.eventInfo.length - event.eventInfo.length / 2).toInt())}...."),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: () async {
                    if (event.attendees.length < event.maxMembers) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(event.id)
                            .update({
                          'attendees': FieldValue.arrayUnion([
                            "${currentUser.firstName} ${currentUser.lastName}"
                          ]),
                        });

                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(event.id)
                            .update({
                          'emails': FieldValue.arrayUnion([currentUser.email]),
                        });

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              surfaceTintColor: Colors.red,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              title: const Text('Signed up!'),
                              content: const Text(
                                  'Thank you for signing up for this event! Our system is working to process your sign up. Please log back into the application to see this event in your signed up events.'),
                              actions: <Widget>[
                                TextButton(
                                  style: const ButtonStyle(
                                    backgroundColor:
                                        WidgetStatePropertyAll(Colors.red),
                                    foregroundColor:
                                        WidgetStatePropertyAll(Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      } catch (e) {
                        debugPrint("Failed to add attendee: $e");
                      }

                      // Assuming currentUser is defined elsewhere in your code and is not null
                      if (FirebaseAuth.instance.currentUser != null) {
                        DocumentReference userDocRef = FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid);

                        // Step 1: Retrieve the current list of events
                        userDocRef
                            .get()
                            .then((DocumentSnapshot documentSnapshot) {
                          if (documentSnapshot.exists) {
                            List<dynamic>? events =
                                documentSnapshot.get('events');
                            if (events != null && !events.contains(event.id)) {
                              // Step 2: Add the new event ID to the list
                              events.add(event.id);
                              // Step 3: Update the user's document with the new list of events
                              userDocRef.update({
                                'events': events,
                              });
                            }
                          }
                        });
                      }
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            surfaceTintColor: Colors.red,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            title: const Text('Event Full'),
                            content: const Text('No more spots available.'),
                            actions: <Widget>[
                              TextButton(
                                style: const ButtonStyle(
                                  backgroundColor:
                                      WidgetStatePropertyAll(Colors.red),
                                  foregroundColor:
                                      WidgetStatePropertyAll(Colors.white),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllEventsPageState extends State<AllEventsPage> {
  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot<Map<String, dynamic>>> eventsStream =
        FirebaseFirestore.instance.collection('events').snapshots();
    Color userChosenAccent = Colors.red;
    TextEditingController eventNameController = TextEditingController();
    debugPrint(currentUser.email);
    return Scaffold(
      floatingActionButton: currentUser.isAdmin
          ? FloatingActionButton(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              child: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    surfaceTintColor: userChosenAccent,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: const Align(
                      alignment: Alignment.topCenter,
                      child: Text("Choose Your Event Type"),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //Regular Events Code
                        TextButton(
                          style: ButtonStyle(
                            overlayColor: WidgetStatePropertyAll(
                                userChosenAccent.withOpacity(0.3)),
                            backgroundColor: const WidgetStatePropertyAll(
                                Colors.transparent),
                            foregroundColor:
                                WidgetStatePropertyAll(userChosenAccent),
                            surfaceTintColor:
                                WidgetStatePropertyAll(userChosenAccent),
                          ),
                          onPressed: () async {
                            Event newEvent = Event();

                            setState(() {});

                            newEvent.eventName = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                surfaceTintColor: userChosenAccent,
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                title: const Center(
                                  child:
                                      Text("What is the name of this event?"),
                                ),
                                content: TextFormField(
                                  controller: eventNameController,
                                  decoration: const InputDecoration(
                                    hintText: "Event Name",
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    style: ButtonStyle(
                                      overlayColor: WidgetStatePropertyAll(
                                        userChosenAccent.withOpacity(0.3),
                                      ),
                                      backgroundColor:
                                          const WidgetStatePropertyAll(
                                              Colors.transparent),
                                      foregroundColor: WidgetStatePropertyAll(
                                          userChosenAccent),
                                      surfaceTintColor: WidgetStatePropertyAll(
                                          userChosenAccent),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(
                                          context, eventNameController.text);
                                    },
                                    child: const Text("Submit"),
                                  )
                                ],
                              ),
                            );
                            newEvent.eventInfo = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                surfaceTintColor: userChosenAccent,
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                title: const Center(
                                  child: Text(
                                      "Enter information about the event here."),
                                ),
                                content: TextFormField(
                                  controller: eventNameController,
                                  decoration: const InputDecoration(
                                    hintText: "Event Info",
                                  ),
                                  minLines: 3,
                                  maxLines: 5,
                                ),
                                actions: [
                                  TextButton(
                                    style: ButtonStyle(
                                      overlayColor: WidgetStatePropertyAll(
                                        userChosenAccent.withOpacity(0.3),
                                      ),
                                      backgroundColor:
                                          const WidgetStatePropertyAll(
                                              Colors.transparent),
                                      foregroundColor: WidgetStatePropertyAll(
                                          userChosenAccent),
                                      surfaceTintColor: WidgetStatePropertyAll(
                                          userChosenAccent),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(
                                          context, eventNameController.text);
                                    },
                                    child: const Text("Submit"),
                                  )
                                ],
                              ),
                            );
                            if (!mounted) return;
                            newEvent.eventDate = await showDatePicker(
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 1000)),
                              context: context,
                              helpText: "Event Date",
                            );
                            if (!mounted) return;
                            newEvent.eventStart = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              helpText: "Start Time",
                            );
                            if (!mounted) return;
                            newEvent.eventFinish = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              helpText: "End Time",
                            );

                            newEvent.maxMembers = 0;

                            newEvent.maxMembers = await showDialog<double>(
                                  context: context,
                                  builder: (context) {
                                    double tempMaxMembers = newEvent
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
                                                maxHeight:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.3),
                                            child: Slider(
                                              activeColor: Colors.red,
                                              inactiveColor:
                                                  Colors.red.shade900,
                                              max: 100,
                                              divisions: 100,
                                              label: tempMaxMembers
                                                  .round()
                                                  .toString(),
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
                                            overlayColor:
                                                WidgetStateProperty.all(
                                                    userChosenAccent
                                                        .withOpacity(0.3)),
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
                                newEvent
                                    .maxMembers; // If the dialog is dismissed, retain the original value

                            String eventFinishAsString =
                                "${newEvent.eventFinish!.hour.toString()}:${newEvent.eventFinish!.minute.toString()}";
                            String eventStartAsString =
                                "${newEvent.eventStart!.hour.toString()}:${newEvent.eventStart!.minute.toString()}";

                            newEvent.emails = [];

                            try {
                              DocumentReference docRef = await FirebaseFirestore
                                  .instance
                                  .collection('events')
                                  .add({
                                'eventName': newEvent.eventName,
                                'eventInfo': newEvent.eventInfo,
                                'maxMembers': newEvent.maxMembers,
                                'currentMembers': newEvent.currentMembers,
                                'eventDate':
                                    newEvent.eventDate!.toIso8601String(),
                                'eventStart': eventStartAsString,
                                'eventFinish': eventFinishAsString,
                                'attendees': newEvent.attendees,
                                'id': "placeholder",
                                'emails': newEvent.emails,
                              });

                              try {
                                await docRef.update({
                                  'id': docRef
                                      .id, // Replace 'yourNewUUID' with the actual UUID you want to set
                                });
                                debugPrint(
                                    'Document ID field updated successfully.');
                              } catch (e) {
                                debugPrint('Failed to update document: $e');
                              }
                              // Refresh the list of events
                              setState(() {});
                            } catch (e) {
                              debugPrint("Failed to add event: $e");
                            }

                            // Refresh the list of events
                            setState(() {});
                          },
                          child: const Text("Event"),
                        )
                      ],
                    ),
                  ),
                );
              },
            )
          : null,
      backgroundColor: const Color.fromARGB(255, 2, 1, 1),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 32.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Current Events",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: eventsStream,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      color: Colors.red,
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> eventData = doc.data();
                      return EventCard(event: Event.fromJson(eventData));
                    }).toList(),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
