# 📥 User Input Flow - Where Model Inputs Are Stored

## Complete Trace of User Input → Model Input

---

## 1️⃣ **FRONTEND: Initial Questionnaire Input**

### Location: `lib/screens/initial_questionnaire_screen.dart`

**Storage:**
```dart
final Map<int, int> _answers = {}; // question_index -> answer (0-4 scale)
```

**Where it's collected:**
- Line ~100: `_answerQuestion(int answer)` method
- User selects: Never (0), Rarely (1), Sometimes (2), Often (3), Very Often (4)
- Stored as: `_answers[questionIndex] = answerValue`

**Example:**
```dart
_answers[0] = 3  // Question 0 answered as "Often"
_answers[1] = 4  // Question 1 answered as "Very Often"
```

**Passed to:**
- Line ~145: Passed to `ADHDChatScreen` as `questionnaireAnswers: _answers`

---

## 2️⃣ **FRONTEND: ADHD Chat Interview Input**

### Location: `lib/screens/adhd_chat_screen.dart`

**Storage:**

#### **Text Answers:**
```dart
final Map<int, String> _questionAnswers = {}; // question_index -> user_answer_text
```

**Where collected:**
- Line ~320: `_submitTextAnswer(String text)` method
- User types answer in TextField
- Stored as: `_questionAnswers[_currentQuestionIndex] = text`

**Example:**
```dart
_questionAnswers[0] = "Yes, I often find it hard to focus"
_questionAnswers[1] = "Sometimes I make mistakes when I'm not paying attention"
```

#### **Video Recordings:**
```dart
final Map<int, String?> _questionVideos = {}; // question_index -> video_path
```

**Where collected:**
- Line ~266: `_stopVideoRecording()` method
- Video file path stored: `_questionVideos[_currentQuestionIndex] = videoFile.path`

**Example:**
```dart
_questionVideos[3] = "/data/user/0/com.example.mindful/app_flutter/adhd_q3_1234567890.mp4"
_questionVideos[4] = "/data/user/0/com.example.mindful/app_flutter/adhd_q4_1234567891.mp4"
```

**Initial Questionnaire Answers (from previous screen):**
```dart
widget.questionnaireAnswers  // Map<int, int> passed from InitialQuestionnaireScreen
```

---

## 3️⃣ **FRONTEND: Data Preparation for Backend**

### Location: `lib/screens/adhd_chat_screen.dart` - `_completeScreening()` method

**Line ~292-301:**
```dart
// Prepare questionnaire data for behavior model
Map<String, dynamic> questionnaireData = {};
for (var entry in widget.questionnaireAnswers.entries) {
  questionnaireData['q${entry.key}'] = entry.value;  // Initial questionnaire answers
}
for (var entry in _questionAnswers.entries) {
  questionnaireData['adhd_q${entry.key}'] = entry.value;  // ADHD chat answers
}
```

**Line ~303-310:**
```dart
// Collect video files
File? videoFile;
if (_questionVideos.isNotEmpty) {
  final firstVideoPath = _questionVideos.values.firstWhere(
    (path) => path != null, 
    orElse: () => null
  );
  if (firstVideoPath != null) {
    videoFile = File(firstVideoPath);
  }
}
```

**Sent to Backend:**
- Line ~312: `_modelService.screenADHD(questionnaireData: questionnaireData, videoFile: videoFile)`

---

## 4️⃣ **FRONTEND → BACKEND: API Call**

### Location: `lib/services/model_service.dart` - `screenADHD()` method

**Line ~50-75:**
```dart
Future<Map<String, dynamic>> screenADHD({
  File? videoFile,
  File? audioFile,
  Map<String, dynamic>? questionnaireData,
}) async {
  var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/screening/adhd'));
  
  // Add questionnaire data
  if (questionnaireData != null) {
    request.fields['questionnaire_data'] = json.encode(questionnaireData);
    // Example: {"q0":3,"q1":4,"adhd_q0":"Yes, I often...","adhd_q1":"Sometimes..."}
  }
  
  // Add video file
  if (videoFile != null) {
    request.files.add(
      await http.MultipartFile.fromPath('video_file', videoFile.path)
    );
  }
}
```

**What's sent:**
- `questionnaire_data`: JSON string with all answers
- `video_file`: Multipart file upload
- `audio_file`: (optional, not currently used in ADHD flow)

---

## 5️⃣ **BACKEND: API Endpoint Receives Input**

### Location: `backend/main.py` - `/screening/adhd` endpoint

**Line ~160-174:**
```dart
@app.post("/screening/adhd")
async def screen_adhd(
    video_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    questionnaire_data: Optional[str] = Form(None)
):
    # Parse questionnaire data
    questionnaire_dict = None
    if questionnaire_data:
        questionnaire_dict = json.loads(questionnaire_data)
        # Now: {"q0": 3, "q1": 4, "adhd_q0": "Yes, I often...", ...}
```

**Received as:**
- `questionnaire_data`: JSON string → parsed to Python dict
- `video_file`: FastAPI UploadFile object
- `audio_file`: FastAPI UploadFile object (optional)

---

## 6️⃣ **BACKEND: Feature Extraction**

### Location: `backend/services/feature_extractor.py`

**For Video (Eye + Facial models):**
```python
# Line ~81-93: extract_face_features()
face_features = await feature_extractor.extract_face_features(video_file)
# Returns: {"face_frames": [...], "num_faces": 1}

# Line ~95-107: extract_eye_features()
eye_features = await feature_extractor.extract_eye_features(video_file)
# Returns: {"mean_fixation_duration_ms": 200.0, "fixation_count": 300, ...}
```

**For Audio (Voice model):**
```python
# Line ~68-79: extract_from_audio()
audio_features = await feature_extractor.extract_from_audio(audio_file)
# Returns: {"mfcc": [...], "chroma": [...], "combined": [59 features]}
```

**For Questionnaire (Behavior model):**
```python
# questionnaire_dict passed directly to model
# Format: {"q0": 3, "q1": 4, "adhd_q0": "Yes...", ...}
```

---

## 7️⃣ **BACKEND: Model Input Preparation**

### Location: `backend/services/model_router.py`

#### **ADHD Behavior Model:**
**Line ~186-212:**
```python
async def predict_adhd_behavior(self, features: Dict[str, Any]) -> Dict[str, Any]:
    # Load feature names from model config
    feature_names = self.model_loader.load_json(features_path)
    # Example: ["ACC", "ACC_TIME", "HRV", "CPT_II", ...]
    
    # Build feature vector
    feature_vector = []
    for feat_name in feature_names:
        feature_vector.append(features.get(feat_name, 0.0))
        # Maps questionnaire answers to model's expected features
    
    feature_array = np.array(feature_vector).reshape(1, -1)
    # This is the ACTUAL INPUT to the model
```

**Input Format:**
- `features`: Dict mapping feature names to values
- Example: `{"ACC": 1, "ACC_TIME": 16.0, "HRV": 1, ...}`

#### **ADHD Eye Model:**
**Line ~214-251:**
```python
async def predict_adhd_eye(self, eye_features: Dict[str, Any]) -> Dict[str, Any]:
    # Extract features from video
    feature_cols = [
        "mean_fixation_duration_ms", "fixation_count", "saccade_count",
        "blink_rate_per_min", "gaze_dispersion_deg", "pupil_diameter_mean_mm",
        "omission_errors", "commission_errors", "reaction_time_mean_ms",
        "reaction_time_std_ms"
    ]
    
    # Build feature vector
    feature_vector = [eye_features.get(col, 0.0) for col in feature_cols]
    feature_df = pd.DataFrame([feature_vector], columns=feature_cols)
    # This DataFrame is the ACTUAL INPUT to the model
```

**Input Format:**
- `eye_features`: Dict with eye-tracking metrics
- Example: `{"mean_fixation_duration_ms": 200.0, "fixation_count": 300, ...}`

#### **ADHD Voice Model:**
**Line ~253-290:**
```python
async def predict_adhd_voice(self, audio_file: UploadFile, config: Dict[str, Any]) -> Dict[str, Any]:
    # Extract audio features
    audio_features = await self.feature_extractor.extract_from_audio(audio_file)
    # Returns: {"combined": [59 features]}
    
    # Prepare features
    features = np.array(audio_features["combined"]).reshape(1, -1)
    features_scaled = scaler.transform(features)
    # This scaled array is the ACTUAL INPUT to CNN/SVM models
```

**Input Format:**
- `audio_features["combined"]`: 59-dimensional feature vector
- [MFCC features (40) + Chroma features (12) + Contrast features (7)]

#### **ADHD Facial Model:**
**Line ~292-328:**
```python
async def predict_adhd_facial(self, video_file: UploadFile, config: Dict[str, Any]) -> Dict[str, Any]:
    # Extract face features
    face_features = await self.feature_extractor.extract_face_features(video_file)
    face_frame = face_features["face_frames"][0]  # Use first detected face
    
    # Preprocess for ResNet50
    face_frame_rgb = cv2.cvtColor(face_frame, cv2.COLOR_BGR2RGB)
    face_frame_resized = cv2.resize(face_frame_rgb, (224, 224))
    face_array = np.expand_dims(face_frame_resized / 255.0, axis=0)
    # Shape: (1, 224, 224, 3) - This is the ACTUAL INPUT to the model
```

**Input Format:**
- `face_array`: NumPy array shape (1, 224, 224, 3)
- Normalized RGB image ready for ResNet50

---

## 📍 **SUMMARY: Where to Find User Inputs**

### **Frontend Storage (Temporary - During Session)**

1. **Initial Questionnaire Answers:**
   - File: `lib/screens/initial_questionnaire_screen.dart`
   - Variable: `_answers` (Map<int, int>)
   - Location: Line ~30

2. **ADHD Chat Text Answers:**
   - File: `lib/screens/adhd_chat_screen.dart`
   - Variable: `_questionAnswers` (Map<int, String>)
   - Location: Line ~35

3. **ADHD Chat Video Recordings:**
   - File: `lib/screens/adhd_chat_screen.dart`
   - Variable: `_questionVideos` (Map<int, String?>)
   - Location: Line ~36
   - **Physical Location**: Device storage at paths like:
     - `/data/user/0/com.example.mindful/app_flutter/adhd_q3_1234567890.mp4`

### **Backend Processing (Temporary - During Request)**

4. **Parsed Questionnaire Data:**
   - File: `backend/main.py`
   - Variable: `questionnaire_dict` (Dict[str, Any])
   - Location: Line ~172-174
   - Format: `{"q0": 3, "q1": 4, "adhd_q0": "Yes...", ...}`

5. **Extracted Features (Before Model Input):**
   - File: `backend/services/feature_extractor.py`
   - Variables:
     - `eye_features` (Dict) - Line ~95-107
     - `face_features` (Dict) - Line ~81-93
     - `audio_features` (Dict) - Line ~68-79

6. **Final Model Inputs (Ready for Models):**
   - File: `backend/services/model_router.py`
   - Variables:
     - **Behavior**: `feature_array` (numpy array) - Line ~200
     - **Eye**: `feature_df` (pandas DataFrame) - Line ~235
     - **Voice**: `features_scaled` (numpy array) - Line ~269
     - **Facial**: `face_array` (numpy array) - Line ~313

---

## 🔍 **How to Access User Inputs**

### **During Development/Debugging:**

1. **Add print statements:**
   ```python
   # In backend/main.py, line ~174
   print("Questionnaire data received:", questionnaire_dict)
   
   # In backend/services/model_router.py
   print("Feature vector for behavior model:", feature_vector)
   print("Eye features:", eye_features)
   ```

2. **Add logging:**
   ```python
   import logging
   logger = logging.getLogger(__name__)
   logger.info(f"User questionnaire: {questionnaire_dict}")
   ```

3. **Return in API response (for debugging):**
   ```python
   return {
       "success": True,
       "debug": {
           "questionnaire_received": questionnaire_dict,
           "video_received": video_file.filename if video_file else None,
       },
       "fused_result": fused_result,
   }
   ```

### **In Production:**

- User inputs are **NOT permanently stored** by default
- They exist only during the request lifecycle
- To store them, you'd need to add database logging

---

## 📝 **Current Input Flow Diagram**

```
USER INPUT
    │
    ├─ Initial Questionnaire (12 questions)
    │   └─ Stored in: _answers Map<int, int>
    │       └─ Passed to: ADHDChatScreen.widget.questionnaireAnswers
    │
    ├─ ADHD Chat Text Answers (8 questions)
    │   └─ Stored in: _questionAnswers Map<int, String>
    │
    └─ ADHD Chat Video Recordings (optional)
        └─ Stored in: _questionVideos Map<int, String?> (file paths)
            └─ Physical files: Device storage (/app_flutter/adhd_q*.mp4)
    │
    ▼
_completeScreening() prepares data
    │
    ├─ questionnaireData = {
    │     "q0": 3, "q1": 4, ... (from initial)
    │     "adhd_q0": "Yes...", ... (from chat)
    │   }
    │
    └─ videoFile = File(_questionVideos[first_video_path])
    │
    ▼
HTTP POST to /screening/adhd
    │
    ├─ questionnaire_data: JSON string
    └─ video_file: Multipart file
    │
    ▼
Backend receives
    │
    ├─ questionnaire_dict = json.loads(questionnaire_data)
    └─ video_file = UploadFile object
    │
    ▼
Feature Extraction
    │
    ├─ questionnaire_dict → (directly to behavior model)
    ├─ video_file → extract_eye_features() → eye_features Dict
    └─ video_file → extract_face_features() → face_frames List
    │
    ▼
Model Input Preparation
    │
    ├─ Behavior: questionnaire_dict → feature_vector → feature_array
    ├─ Eye: eye_features → feature_vector → feature_df
    ├─ Voice: audio_file → audio_features → features_scaled
    └─ Facial: face_frames → face_array (224x224x3)
    │
    ▼
MODEL PREDICTION (Actual Model Input)
```

---

## 🎯 **Key Locations Summary**

| Input Type | Frontend Storage | Backend Storage | Model Input Format |
|------------|-----------------|-----------------|-------------------|
| **Questionnaire** | `_answers` Map | `questionnaire_dict` Dict | `feature_array` numpy array |
| **Text Answers** | `_questionAnswers` Map | `questionnaire_dict` Dict | `feature_array` numpy array |
| **Video** | `_questionVideos` Map (paths) | `video_file` UploadFile | `face_array` (224x224x3) or `feature_df` |
| **Audio** | Not collected yet | `audio_file` UploadFile | `features_scaled` (59 dims) |

---

## ⚠️ **Important Notes**

1. **No Permanent Storage**: User inputs are NOT saved to database by default
2. **Temporary Files**: Video files are stored temporarily on device, not uploaded permanently
3. **Feature Mapping**: Questionnaire answers need proper mapping to match model's expected feature names
4. **Current Limitation**: Only first video is used if multiple videos recorded

---

## 🔧 **To Add Input Logging**

If you want to store user inputs for analysis:

1. **Add to backend/main.py:**
   ```python
   # After receiving questionnaire_data
   import json
   with open('user_inputs_log.json', 'a') as f:
       json.dump({
           'timestamp': datetime.now().isoformat(),
           'questionnaire': questionnaire_dict,
           'video_filename': video_file.filename if video_file else None
       }, f)
       f.write('\n')
   ```

2. **Or add to database:**
   ```python
   # Store in Supabase or your database
   await supabase.from('screening_inputs').insert({
       'user_id': user_id,
       'questionnaire_data': questionnaire_dict,
       'created_at': datetime.now()
   })
   ```

---

This document shows exactly where user inputs are stored at each stage of the flow!

