import 'dart:html' as html;

void playNotificationSound() {
  try {
    // A tiny, standard base64 'ding' sound (synthesized sine wave beep)
    const String beepBase64 = "data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YVgGAACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC1sbnBx8rP0tTW2Nvc3t/g4uTl5ujo6err7O3u7/Dx8vP09fb3+Pn6+/z9/v8AAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHx8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+A";
    
    final html.AudioElement audio = html.AudioElement(beepBase64)
      ..autoplay = true
      ..volume = 1.0;
      
    // Append to body briefly to ensure browser playback rules, then play
    html.document.body?.append(audio);
    audio.play().then((_) {
      Future.delayed(const Duration(seconds: 2), () => audio.remove());
    }).catchError((e) {
      
    });
  } catch (e) {
    
  }
}


