import 'dart:io';
import 'package:mindful/services/job_service.dart';

void main() async {
  print("Testing Depression Job Submission from Dart...");
  try {
    String jobId = await JobService.submitDepressionJob(
      videoFile: null,
      questionnaireData: {
        "condition": "depression",
        "initial_q_1": "Feeling sad",
        "depression_q_0_text": "I feel tired all the time."
      }
    );
    print("Submitted! Job ID: \$jobId");
    
    // Poll for result
    var result = await JobService.pollJobUntilDone(
      jobId, 
      pollInterval: Duration(seconds: 2), 
      maxAttempts: 10,
      onStatus: (status, err) => print("  Status: \$status")
    );
    print("Final Result: \$result");
  } catch (e) {
    print("Error: \$e");
  }
}
