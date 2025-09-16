// // import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class MyDateUtil {
//   static String getFormattedTime({
//     required BuildContext context,
//     required Timestamp? time, // Accept Timestamp instead of String
//   }) {
//     if (time == null) return "Unknown"; // Handle null timestamps gracefully

//     final date = time.toDate(); // Convert Timestamp to DateTime
//     return TimeOfDay.fromDateTime(date).format(context);
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyDateUtil {
  static String getFormattedTime(
      {required BuildContext context, required Timestamp? time}) {
    if (time == null) return '';

    DateTime messageDate = time.toDate();
    DateTime now = DateTime.now();

    // Format cases
    if (DateFormat('yMd').format(messageDate) ==
        DateFormat('yMd').format(now)) {
      // If the message is from today, show only time (e.g., "10:45 AM")
      return DateFormat('hh:mm a').format(messageDate);
    } else if (DateFormat('yMd').format(messageDate) ==
        DateFormat('yMd').format(now.subtract(Duration(days: 1)))) {
      // If the message is from yesterday, return "Yesterday"
      return "Yesterday";
    } else if (messageDate.year == now.year) {
      // If the message is from the same year, show "MM/dd"
      return DateFormat('MM/dd').format(messageDate);
    } else {
      // If the message is from a different year, show "MM/dd/yyyy"
      return DateFormat('MM/dd/yyyy').format(messageDate);
    }
      }
   static String formatTime(dynamic dateTime) {
   
    if (dateTime == null) return "Unknown";

    DateTime lastSeen;
    
    if (dateTime is Timestamp) {
      lastSeen = dateTime.toDate(); // Convert Firestore Timestamp to DateTime
    } else if (dateTime is DateTime) {
      lastSeen = dateTime;
    } else {
      return "Unknown";
    }

    DateTime now = DateTime.now();
    Duration difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return "Just now"; // If last seen within a minute
    } else if (difference.inHours < 24 &&
        lastSeen.day == now.day &&
        lastSeen.month == now.month &&
        lastSeen.year == now.year) {
      return "Today at ${DateFormat('hh:mm a').format(lastSeen)}"; // Today
    } else if (difference.inHours >= 24 &&
        lastSeen.day == now.subtract(Duration(days: 1)).day) {
      return "Yesterday at ${DateFormat('hh:mm a').format(lastSeen)}"; // Yesterday
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(lastSeen); // Older dates
    }
  }
    }
  

