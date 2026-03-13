"""
Feature Extraction Service
Extracts features from video, audio, face, and eye-tracking data

Updated:
- Extract audio from video using ffmpeg (MP4 -> WAV) so voice model can work.
- Stable UploadFile -> path save
- Non-constant eye heuristics (motion-based)
"""

import os
import cv2
import numpy as np
import librosa
import tempfile
import subprocess
import urllib.request
from typing import Dict, List, Any, Optional
from fastapi import UploadFile


class FeatureExtractor:
    def __init__(self):
        self.temp_dir = tempfile.mkdtemp()

    # -----------------------------
    # UploadFile -> temp path helpers
    # -----------------------------
    async def _save_upload_to_path(self, up: UploadFile, prefix: str, suffix: str) -> str:
        path = os.path.join(self.temp_dir, f"{prefix}_{up.filename}")
        if not path.lower().endswith(suffix.lower()):
            path = path + suffix

        # reset pointer and stream-save
        await up.seek(0)
        with open(path, "wb") as f:
            while True:
                chunk = await up.read(1024 * 1024)
                if not chunk:
                    break
                f.write(chunk)
        await up.seek(0)
        return path

    def _cleanup(self, path: Optional[str]) -> None:
        try:
            if path and os.path.exists(path):
                os.remove(path)
        except Exception:
            pass

    # -----------------------------
    # Public API (UploadFile)
    # -----------------------------
    async def extract_from_video(self, video_file: UploadFile) -> Dict[str, Any]:
        """
        Returns: frames_count + eye + face + audio_features (from video)
        """
        temp_video_path = await self._save_upload_to_path(video_file, "video", ".mp4")
        temp_audio_path = None

        try:
            frames = self._extract_frames(temp_video_path)
            eye_features = self._extract_eye_features_heuristic(frames)
            face = self._extract_face_from_frames(frames)

            # ✅ NEW: extract audio from video via ffmpeg (so voice model can work)
            audio_features = await self._extract_audio_from_video_path(temp_video_path)

            return {
                "frames_count": len(frames),
                "eye_features": eye_features,
                "face_features": face,
                "audio_features": audio_features,
            }
        finally:
            self._cleanup(temp_video_path)
            self._cleanup(temp_audio_path)

    async def extract_from_audio(self, audio_file: UploadFile) -> Dict[str, Any]:
        temp_path = await self._save_upload_to_path(audio_file, "audio", ".wav")
        try:
            return await self._extract_audio_features(temp_path)
        finally:
            self._cleanup(temp_path)

    async def extract_face_features(self, video_file: UploadFile) -> Dict[str, Any]:
        temp_path = await self._save_upload_to_path(video_file, "face", ".mp4")
        try:
            frames = self._extract_frames(temp_path)
            return self._extract_face_from_frames(frames)
        finally:
            self._cleanup(temp_path)

    async def extract_eye_features(self, video_file: UploadFile) -> Dict[str, Any]:
        temp_path = await self._save_upload_to_path(video_file, "eye", ".mp4")
        try:
            frames = self._extract_frames(temp_path)
            return self._extract_eye_features_heuristic(frames)
        finally:
            self._cleanup(temp_path)

    async def extract_text_features(self, text_data: str) -> Dict[str, Any]:
        return {"text": text_data, "processed": True}

    # -----------------------------
    # Public API (path-based) used by ModelRouter
    # -----------------------------
    async def extract_eye_features_from_path(self, video_path: str) -> Dict[str, Any]:
        frames = self._extract_frames(video_path)
        return self._extract_eye_features_heuristic(frames)

    async def extract_audio_features_from_path(self, audio_path: str) -> Dict[str, Any]:
        return await self._extract_audio_features(audio_path)

    async def extract_audio_from_video_path(self, video_path: str) -> Dict[str, Any]:
        """
        Convenience: MP4 -> WAV -> audio features
        """
        return await self._extract_audio_from_video_path(video_path)

    async def extract_first_face_frame_from_path(self, video_path: str) -> Optional[np.ndarray]:
        frames = self._extract_frames(video_path, max_frames=40)
        face_data = self._extract_face_from_frames(frames)
        if face_data.get("face_frames"):
            return face_data["face_frames"][0]
        return None

<<<<<<< HEAD
=======
    async def extract_facial_aus_sequence(self, video_path: str, max_frames: int = 300) -> List[List[float]]:
        """
        Extracts facial Action Units (AUs) intensities for a sequence of frames.
        Returns a list of lists, where each sublist contains the AU intensities for one frame.
        """
        frames = self._extract_frames(video_path, max_frames=max_frames)
        if not frames:
            return []

        # Attempt to use mediapipe if available, otherwise fallback to zeros
        try:
            import mediapipe as mp
            mp_face_mesh = mp.solutions.face_mesh
            with mp_face_mesh.FaceMesh(
                static_image_mode=False,
                max_num_faces=1,
                refine_landmarks=True,
                min_detection_confidence=0.5
            ) as face_mesh:
                au_sequences = []
                for frame in frames:
                    results = face_mesh.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
                    if results.multi_face_landmarks:
                        # Extract 17 proxy intensities from landmarks (approx AU mapping)
                        # This is a heuristic mapping for the prototype
                        landmarks = results.multi_face_landmarks[0].landmark
                        # Just a mapping of landmark distances as proxies for AU intensity
                        # Example: brow furrow, eye lid height, mouth width, etc.
                        au_proxies = [
                            landmarks[10].y - landmarks[151].y, # AU1 Inner Brow
                            landmarks[336].y - landmarks[285].y, # AU2 Outer Brow
                            landmarks[107].y - landmarks[66].y,  # AU4 Brow Lowerer
                            landmarks[159].y - landmarks[145].y, # AU5 Upper Lid
                            landmarks[386].y - landmarks[374].y, # AU7 Lid Tighten
                            landmarks[61].x - landmarks[291].x,  # AU10 Upper Lip Raise
                            landmarks[13].y - landmarks[14].y,   # AU12 Lip Corner Pull
                            landmarks[17].y - landmarks[0].y,    # AU14 Dimpler
                            landmarks[61].y - landmarks[291].y,  # AU15 Lip Corner Depress
                            landmarks[13].y - landmarks[14].y,   # AU17 Chin Raise
                            landmarks[13].y - landmarks[14].y,   # AU20 Lip Stretcher
                            landmarks[13].y - landmarks[14].y,   # AU23 Lip Tighten
                            landmarks[13].y - landmarks[14].y,   # AU25 Lips Part
                            landmarks[13].y - landmarks[14].y,   # AU26 Jaw Drop
                            0.0, 0.0, 0.0 # Padding to 17
                        ]
                        au_sequences.append(au_proxies)
                    else:
                        au_sequences.append([0.0] * 17)
                return au_sequences
        except (ImportError, Exception):
            # Fallback: Neutral sequence (zeros)
            return [[0.0] * 17 for _ in range(len(frames))]

>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
    def extract_face_crop_224_from_url(self, image_url: str) -> Dict[str, Any]:
        """
        Download image from URL, detect face, crop to 224x224 RGB.
        Returns dict with "face_rgb" (np array) and metadata.
        """
        try:
            # 1. Download image
            resp = urllib.request.urlopen(image_url)
            image_bytes = np.asarray(bytearray(resp.read()), dtype="uint8")
            image = cv2.imdecode(image_bytes, cv2.IMREAD_COLOR)

            if image is None:
                return {"error": "Could not decode image from URL"}

            # 2. Detect face
            face_cascade = cv2.CascadeClassifier(
                cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
            )
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(gray, 1.1, 4)

            if len(faces) == 0:
                return {"error": "No face detected in image", "faces_count": 0}

            # 3. Crop first face
            (x, y, w, h) = faces[0]
            face_roi = image[y:y+h, x:x+w]
            face_resized = cv2.resize(face_roi, (224, 224))
            
            # Convert BGR to RGB (TF models usually expect RGB)
            face_rgb = cv2.cvtColor(face_resized, cv2.COLOR_BGR2RGB)

            return {
                "face_rgb": face_rgb,
                "faces_count": len(faces),
                "bbox": [int(x), int(y), int(w), int(h)]
            }

        except Exception as e:
            return {"error": f"Error processing image url: {str(e)}"}

    # -----------------------------
    # Core extractors
    # -----------------------------
    def _extract_frames(self, video_path: str, max_frames: int = 30) -> List[np.ndarray]:
        cap = cv2.VideoCapture(video_path)
        frames = []
        while cap.isOpened() and len(frames) < max_frames:
            ret, frame = cap.read()
            if not ret:
                break
            frames.append(frame)
        cap.release()
        return frames

    async def _extract_audio_from_video_path(self, video_path: str) -> Dict[str, Any]:
        """
        ✅ Extract audio from video using ffmpeg.
        Produces a temp WAV and then calls _extract_audio_features().
        """
        wav_path = os.path.join(self.temp_dir, f"audio_from_video_{os.path.basename(video_path)}.wav")

        # ffmpeg command:
        # -y overwrite, -vn no video, 16k mono PCM wav
        cmd = [
            "ffmpeg",
            "-y",
            "-i", video_path,
            "-vn",
            "-ac", "1",
            "-ar", "16000",
            "-f", "wav",
            wav_path
        ]

        try:
            proc = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            if proc.returncode != 0:
                return {
                    "error": "ffmpeg failed to extract audio from video",
                    "ffmpeg_stderr": proc.stderr[-800:],  # keep last part only
                }

            if not os.path.exists(wav_path) or os.path.getsize(wav_path) < 2000:
                return {"error": "Extracted audio file is empty or too small"}

            feats = await self._extract_audio_features(wav_path)
            feats["source"] = "extracted_from_video"
            feats["wav_path_temp"] = wav_path  # for debugging if needed
            return feats

        except FileNotFoundError:
            return {
                "error": "ffmpeg not found on server PATH",
                "hint": "Install ffmpeg and ensure 'ffmpeg' command is available."
            }
        except Exception as e:
            return {"error": f"Audio extraction exception: {str(e)}"}
        finally:
            # privacy + cleanup
            self._cleanup(wav_path)

    async def _extract_audio_features(self, audio_path: str) -> Dict[str, Any]:
        """
        Extract MFCC(40) + chroma(12) + contrast(7) => 59 dims
        """
        try:
            y, sr = librosa.load(audio_path, sr=None, duration=3.0)
            if y is None or len(y) < 100:
                return {"error": "Audio too short or unreadable"}

            # normalize
            y = y.astype(np.float32)
            y = y - np.mean(y)
            std = np.std(y) + 1e-8
            y = y / std

            mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40)
            chroma = librosa.feature.chroma_stft(y=y, sr=sr)
            contrast = librosa.feature.spectral_contrast(y=y, sr=sr)

            vec = np.hstack([
                np.mean(mfccs, axis=1),
                np.mean(chroma, axis=1),
                np.mean(contrast, axis=1),
            ]).astype(np.float32)

            return {
                "mfcc": np.mean(mfccs, axis=1).tolist(),
                "chroma": np.mean(chroma, axis=1).tolist(),
                "contrast": np.mean(contrast, axis=1).tolist(),
                "combined": vec.tolist(),
                "shape": list(vec.shape),
                "sr": int(sr),
                "duration_sec": float(len(y) / sr),
            }
        except Exception as e:
            return {"error": str(e)}

    def _extract_face_from_frames(self, frames: List[np.ndarray]) -> Dict[str, Any]:
        face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
        )
        face_frames = []

        for frame in frames:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(gray, 1.1, 4)
            for (x, y, w, h) in faces[:1]:  # take first face only per frame
                face_roi = frame[y:y + h, x:x + w]
                face_resized = cv2.resize(face_roi, (224, 224))
                face_frames.append(face_resized)

        return {
            "face_frames": face_frames,
            "num_faces": len(face_frames),
            "frames_shape": (224, 224, 3) if face_frames else None,
        }

    # -----------------------------
    # Eye heuristic (NON-CONSTANT)
    # -----------------------------
    def _extract_eye_features_heuristic(self, frames: List[np.ndarray]) -> Dict[str, Any]:
        """
        Not true eye-tracking. But produces non-constant features from video dynamics:
        - motion energy (proxy for saccades)
        - blink proxy (motion spikes)
        - gaze dispersion proxy (motion variance)
        """
        if not frames:
            return self._default_eye_features()

        small = []
        for f in frames:
            g = cv2.cvtColor(f, cv2.COLOR_BGR2GRAY)
            g = cv2.resize(g, (160, 90))
            small.append(g.astype(np.float32))

        diffs = []
        for i in range(1, len(small)):
            diffs.append(float(np.mean(np.abs(small[i] - small[i - 1]))))

        motion_mean = float(np.mean(diffs)) if diffs else 0.0
        motion_std = float(np.std(diffs)) if diffs else 0.0

        num_frames = len(frames)
        fixation_count = int(max(1, num_frames * (1.5 + motion_mean / 20.0)))
        saccade_count = int(max(1, num_frames * (2.0 + motion_std / 10.0)))

        blink_spikes = 0
        if diffs:
            thr = float(np.mean(diffs) + 2.0 * (np.std(diffs) + 1e-6))
            blink_spikes = int(np.sum(np.array(diffs) > thr))

        blink_rate = float(min(60.0, max(0.0, blink_spikes * 10.0)))

        reaction_mean = float(400.0 + motion_mean * 8.0)
        reaction_std = float(80.0 + motion_std * 15.0)

        gaze_dispersion = float(2.0 + motion_std / 5.0)
        pupil_diameter = float(2.5 + min(1.5, motion_mean / 30.0))

        omission = int(max(0, 5 + motion_std))
        commission = int(max(0, 3 + motion_mean / 5.0))

        mean_fix = float(180.0 + max(0.0, 30.0 - motion_mean))

        return {
            "mean_fixation_duration_ms": mean_fix,
            "fixation_count": fixation_count,
            "saccade_count": saccade_count,
            "blink_rate_per_min": blink_rate,
            "gaze_dispersion_deg": gaze_dispersion,
            "pupil_diameter_mean_mm": pupil_diameter,
            "omission_errors": omission,
            "commission_errors": commission,
            "reaction_time_mean_ms": reaction_mean,
            "reaction_time_std_ms": reaction_std,
        }

    def _default_eye_features(self) -> Dict[str, Any]:
        return {
            "mean_fixation_duration_ms": 200.0,
            "fixation_count": 150,
            "saccade_count": 180,
            "blink_rate_per_min": 15.0,
            "gaze_dispersion_deg": 3.5,
            "pupil_diameter_mean_mm": 2.9,
            "omission_errors": 10,
            "commission_errors": 8,
            "reaction_time_mean_ms": 550.0,
            "reaction_time_std_ms": 120.0,
        }
