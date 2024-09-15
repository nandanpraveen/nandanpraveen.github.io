import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:outreachapp/presetobjects.dart';
import 'package:outreachapp/screens/detailedeventviewer.dart';
import 'package:outreachapp/screens/loginpage.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

Future<void> removeAttendeeFromEvent(
    String eventId, String attendeeNameToRemove) async {
  try {
    // Construct the document reference for the event
    DocumentReference eventDocRef =
        FirebaseFirestore.instance.collection('events').doc(eventId);

    // Fetch the event document
    DocumentSnapshot eventSnapshot = await eventDocRef.get();

    // Check if the event exists and has attendees
    if (!eventSnapshot.exists ||
        !eventSnapshot['attendees'].contains(attendeeNameToRemove)) {
      debugPrint('Event does not exist or attendee name is not found.');
      return;
    }

    // Convert the attendees list to a List<dynamic>
    List<dynamic> updatedAttendees = List.from(eventSnapshot['attendees']);

    // Find the index of the attendee to remove
    int indexOfAttendeeToRemove = updatedAttendees
        .indexWhere((attendee) => attendee == attendeeNameToRemove);

    // Remove the attendee from the list
    if (indexOfAttendeeToRemove != -1) {
      updatedAttendees.removeAt(indexOfAttendeeToRemove);
    }

    // Update the event document with the modified attendees list
    await eventDocRef.update({'attendees': updatedAttendees});
    debugPrint('Attendee removed successfully');
  } catch (e) {
    debugPrint('Failed to remove attendee: $e');
  }
}

Future<void> deleteUserEvent(String userId, String eventId) async {
  try {
    // Fetch the current user's document
    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot userSnapshot = await userDocRef.get();

    // Check if the user exists and has events
    if (!userSnapshot.exists || !userSnapshot['events'].contains(eventId)) {
      debugPrint('User does not exist or event ID is not found.');
      return;
    }

    // Remove the event ID from the events array
    List<dynamic> updatedEvents = List.from(userSnapshot['events']);
    updatedEvents.remove(eventId);

    // Update the user document with the modified events array
    await userDocRef.update({'events': updatedEvents});
    debugPrint('Event removed successfully');
  } catch (e) {
    debugPrint('Failed to remove event: $e');
  }
}

class MyEventCard extends StatelessWidget {
  final Event event;

  // ignore: use_key_in_widget_constructors
  const MyEventCard({required this.event});

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
        color: Colors.blue.shade700,
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
                      "${event.eventName.substring(0, min(event.eventInfo.length, 50))}..",
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await deleteUserEvent(
                          FirebaseAuth.instance.currentUser!.uid,
                          event.id,
                        );
                        String attendeeNameToRemove =
                            '${currentUser.firstName} ${currentUser.lastName}';

                        await removeAttendeeFromEvent(
                          event.id,
                          attendeeNameToRemove,
                        );

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              surfaceTintColor: Colors.blue,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              title: const Text('Event deletion processed.'),
                              content: const Text(
                                  'Your deletion of this event from your account has been processed. Our system is working to register this, and will remove the event from this screen the next time you log in.'),
                              actions: <Widget>[
                                TextButton(
                                  style: const ButtonStyle(
                                    backgroundColor:
                                        WidgetStatePropertyAll(Colors.blue),
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
                      },
                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyEventsPageState extends State<MyEventsPage> {
  Color accentColor = Colors.blue;
  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot<Map<String, dynamic>>>? eventsStream;

    if (currentUser.events.isNotEmpty) {
      eventsStream = FirebaseFirestore.instance
          .collection('events')
          .where(
            'id', // Assuming each event document has an 'id' field that matches the event ID in currentUserEventsList
            whereIn: currentUser.events.cast<String>(),
          )
          .snapshots();
    } else {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 32.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "My Signed Up Events",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
            ),
          ),
          const SizedBox(
            width: double.infinity,
            height: 60,
          ),
          const Text(
            "Nothing to see here... sign up for some events!",
            style: TextStyle(
              fontSize: 18,
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(
            width: double.infinity,
            height: 60,
          ),
          TextButton(
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                backgroundColor: WidgetStatePropertyAll(Colors.red),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                currentUser.firstName = '';
                currentUser.firstName = '';
                currentUser.email = '';
                currentUser.password = '';
                currentUser.isAdmin = false;
                currentUser.events = [];

                // ignore: use_build_context_synchronously
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              child: const Text(
                "Sign Out",
              ))
        ],
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 32.0),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              "My Signed Up Events",
              style: TextStyle(
                fontSize: 30,
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
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                    color: Colors.red,
                  );
                }

                if (currentUser.events.isEmpty) {
                  return const Center(child: Text("No events found."));
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> eventData = doc.data();
                    return MyEventCard(event: Event.fromJson(eventData));
                  }).toList(),
                );
              },
            ),
          ),
        ),
        TextButton(
            style: const ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(Colors.white),
              backgroundColor: WidgetStatePropertyAll(Colors.red),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              currentUser.firstName = '';
              currentUser.firstName = '';
              currentUser.email = '';
              currentUser.password = '';
              currentUser.isAdmin = false;
              currentUser.events = [];

              // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
            child: const Text(
              "Sign Out",
            ))
      ],
    );
  }
}
