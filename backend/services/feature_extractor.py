"""
Feature Extraction Service
Extracts features from video, audio, face, and eye-tracking data
"""

import numpy as np
import cv2
import librosa
import tempfile
import os
from typing import Dict, List, Any, Optional
from fastapi import UploadFile
import json
import joblib
from pathlib import Path

# Try to import TensorFlow/Keras for face models
try:
    import tensorflow as tf
    from tensorflow import keras
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    print("Warning: TensorFlow not available. Face models will not work.")


class FeatureExtractor:
    """Extract features from various modalities"""
    
    def __init__(self):
        self.temp_dir = tempfile.mkdtemp()
    
    async def extract_from_video(self, video_file: UploadFile) -> Dict[str, Any]:
        """
        Extract features from video file
        Returns: face frames, audio features, eye features
        """
        # Save uploaded file temporarily
        temp_path = os.path.join(self.temp_dir, f"video_{video_file.filename}")
        with open(temp_path, "wb") as f:
            content = await video_file.read()
            f.write(content)
        
        try:
            # Extract video frames
            frames = self._extract_frames(temp_path)
            
            # Extract audio from video
            audio_features = await self._extract_audio_from_video(temp_path)
            
            # Extract face features
            face_features = self._extract_face_from_frames(frames)
            
            # Extract eye features (simplified - would need proper eye-tracking)
            eye_features = self._extract_eye_from_frames(frames)
            
            return {
                "frames": frames,
                "audio_features": audio_features,
                "face_features": face_features,
                "eye_features": eye_features
            }
        finally:
            # Cleanup
            if os.path.exists(temp_path):
                os.remove(temp_path)
    
    async def extract_from_audio(self, audio_file: UploadFile) -> Dict[str, Any]:
        """Extract audio features (MFCC, chroma, contrast)"""
        temp_path = os.path.join(self.temp_dir, f"audio_{audio_file.filename}")
        with open(temp_path, "wb") as f:
            content = await audio_file.read()
            f.write(content)
        
        try:
            return await self._extract_audio_features(temp_path)
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)
    
    async def extract_face_features(self, video_file: UploadFile) -> Dict[str, Any]:
        """Extract face features from video"""
        temp_path = os.path.join(self.temp_dir, f"face_{video_file.filename}")
        with open(temp_path, "wb") as f:
            content = await video_file.read()
            f.write(content)
        
        try:
            frames = self._extract_frames(temp_path)
            return self._extract_face_from_frames(frames)
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)
    
    async def extract_eye_features(self, video_file: UploadFile) -> Dict[str, Any]:
        """Extract eye-tracking features from video"""
        temp_path = os.path.join(self.temp_dir, f"eye_{video_file.filename}")
        with open(temp_path, "wb") as f:
            content = await video_file.read()
            f.write(content)
        
        try:
            frames = self._extract_frames(temp_path)
            return self._extract_eye_from_frames(frames)
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)
    
    async def extract_text_features(self, text_data: str) -> Dict[str, Any]:
        """Extract features from text (for questionnaire responses)"""
        # This would process questionnaire answers
        # For now, return as-is
        return {"text": text_data, "processed": True}
    
    def _extract_frames(self, video_path: str, max_frames: int = 30) -> List[np.ndarray]:
        """Extract frames from video"""
        cap = cv2.VideoCapture(video_path)
        frames = []
        frame_count = 0
        
        while cap.isOpened() and len(frames) < max_frames:
            ret, frame = cap.read()
            if not ret:
                break
            frames.append(frame)
            frame_count += 1
        
        cap.release()
        return frames
    
    async def _extract_audio_from_video(self, video_path: str) -> Dict[str, Any]:
        """Extract audio from video and get features"""
        # Use ffmpeg to extract audio (simplified - would need proper implementation)
        # For now, try to load as audio file
        try:
            audio, sr = librosa.load(video_path, sr=None, duration=3.0)
            return await self._extract_audio_features_from_array(audio, sr)
        except:
            return {"error": "Could not extract audio from video"}
    
    async def _extract_audio_features(self, audio_path: str) -> Dict[str, Any]:
        """Extract audio features from audio file"""
        try:
            audio, sr = librosa.load(audio_path, sr=None, duration=3.0)
            return await self._extract_audio_features_from_array(audio, sr)
        except Exception as e:
            return {"error": str(e)}
    
    async def _extract_audio_features_from_array(self, audio: np.ndarray, sr: int) -> Dict[str, Any]:
        """Extract MFCC, chroma, and contrast features"""
        # Extract features
        mfccs = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=40)
        chroma = librosa.feature.chroma_stft(y=audio, sr=sr)
        contrast = librosa.feature.spectral_contrast(y=audio, sr=sr)
        
        # Mean pooling to get fixed-length vector
        features = np.hstack([
            np.mean(mfccs, axis=1),
            np.mean(chroma, axis=1),
            np.mean(contrast, axis=1)
        ])
        
        return {
            "mfcc": np.mean(mfccs, axis=1).tolist(),
            "chroma": np.mean(chroma, axis=1).tolist(),
            "contrast": np.mean(contrast, axis=1).tolist(),
            "combined": features.tolist(),
            "shape": features.shape
        }
    
    def _extract_face_from_frames(self, frames: List[np.ndarray]) -> Dict[str, Any]:
        """Extract face regions from frames"""
        # Use OpenCV's face detector (Haar Cascade)
        face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        face_frames = []
        
        for frame in frames:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(gray, 1.1, 4)
            
            for (x, y, w, h) in faces:
                face_roi = frame[y:y+h, x:x+w]
                # Resize to 224x224 for model input
                face_resized = cv2.resize(face_roi, (224, 224))
                face_frames.append(face_resized)
        
        return {
            "face_frames": face_frames,
            "num_faces": len(face_frames),
            "frames_shape": (224, 224, 3) if face_frames else None
        }
    
    def _extract_eye_from_frames(self, frames: List[np.ndarray]) -> Dict[str, Any]:
        """
        Extract eye-tracking features from frames
        Simplified version - would need proper eye-tracking model
        """
        # This is a placeholder - would need actual eye-tracking implementation
        # For now, return synthetic features based on frame analysis
        if not frames:
            return self._get_default_eye_features()
        
        # Simple heuristics (not real eye-tracking)
        num_frames = len(frames)
        
        # Placeholder eye features (would be extracted from actual eye-tracking)
        eye_features = {
            "mean_fixation_duration_ms": 200.0,
            "fixation_count": num_frames * 3,
            "saccade_count": num_frames * 4,
            "blink_rate_per_min": 20.0,
            "gaze_dispersion_deg": 4.5,
            "pupil_diameter_mean_mm": 3.0,
            "omission_errors": 15,
            "commission_errors": 10,
            "reaction_time_mean_ms": 600.0,
            "reaction_time_std_ms": 150.0
        }
        
        return eye_features
    
    def _get_default_eye_features(self) -> Dict[str, Any]:
        """Return default eye features when no frames available"""
        return {
            "mean_fixation_duration_ms": 200.0,
            "fixation_count": 300,
            "saccade_count": 400,
            "blink_rate_per_min": 20.0,
            "gaze_dispersion_deg": 4.5,
            "pupil_diameter_mean_mm": 3.0,
            "omission_errors": 15,
            "commission_errors": 10,
            "reaction_time_mean_ms": 600.0,
            "reaction_time_std_ms": 150.0
        }

