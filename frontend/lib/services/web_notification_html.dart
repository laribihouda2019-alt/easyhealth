import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void requestBrowserNotificationPermission() {
  if (html.Notification.permission != 'granted' && html.Notification.permission != 'denied') {
    html.Notification.requestPermission().then((permission) {
    });
  } else {
  }
}

void showBrowserNotification(String title, String body) {
  if (html.Notification.permission == 'granted') {
    html.Notification(title, body: body);
  } else {
    html.window.alert('$title\n$body');
  }
}


