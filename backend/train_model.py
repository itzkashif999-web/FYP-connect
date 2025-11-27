"""
Train a custom recommendation model on historical student-supervisor matching data
This will be used to validate the AI (Gemma 3:1b) recommendations
"""

import json
import pickle
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.model_selection import train_test_split
import os

class CustomRecommendationModel:
    """
    Custom ML model trained on historical student-supervisor matches
    Uses TF-IDF for text features and cosine similarity for matching
    """
    
    def __init__(self):
        self.vectorizer = TfidfVectorizer(
            max_features=100,
            stop_words='english',
            ngram_range=(1, 2)
        )
        self.supervisor_profiles = []
        self.supervisor_vectors = None
        self.trained = False
        
    def prepare_text_features(self, student_or_supervisor):
        """Combine interests, skills, specialization into single text"""
        text_parts = []
        
        # For students
        if 'interest' in student_or_supervisor:
            interests = student_or_supervisor.get('interest', '')
            if isinstance(interests, list):
                text_parts.extend(interests)
            elif isinstance(interests, str):
                text_parts.append(interests)
                
        if 'skills' in student_or_supervisor:
            skills = student_or_supervisor.get('skills', '')
            if isinstance(skills, list):
                text_parts.extend(skills)
            elif isinstance(skills, str):
                text_parts.append(skills)
        
        # For supervisors
        if 'specialization' in student_or_supervisor:
            text_parts.append(student_or_supervisor.get('specialization', ''))
            
        if 'preferenceAreas' in student_or_supervisor:
            prefs = student_or_supervisor.get('preferenceAreas', '')
            if isinstance(prefs, list):
                text_parts.extend(prefs)
            elif isinstance(prefs, str):
                text_parts.append(prefs)
                
        if 'projectHistoryCategories' in student_or_supervisor:
            history = student_or_supervisor.get('projectHistoryCategories', '')
            if isinstance(history, list):
                text_parts.extend(history)
            elif isinstance(history, str):
                text_parts.append(history)
        
        return ' '.join(str(part).lower() for part in text_parts if part)
    
    def train(self, supervisors, training_data=None):
        """
        Train the model on supervisor profiles
        training_data: Optional list of (student, accepted_supervisor_id) pairs
        """
        print(f"🎓 Training custom model on {len(supervisors)} supervisors...")
        
        # Store supervisor profiles
        self.supervisor_profiles = supervisors
        
        # Extract text features from supervisors
        supervisor_texts = [self.prepare_text_features(sup) for sup in supervisors]
        
        # Fit vectorizer and transform supervisors
        self.supervisor_vectors = self.vectorizer.fit_transform(supervisor_texts)
        
        self.trained = True
        print(f"✅ Model trained successfully!")
        print(f"   Vocabulary size: {len(self.vectorizer.vocabulary_)}")
        
        # If we have training data, evaluate
        if training_data:
            self._evaluate_on_training_data(training_data)
    
    def _evaluate_on_training_data(self, training_data):
        """Evaluate model on historical matches"""
        correct = 0
        top3_correct = 0
        
        for student, accepted_sup_id in training_data:
            predictions = self.predict(student, top_k=5)
            predicted_ids = [p['id'] for p in predictions]
            
            if predicted_ids and predicted_ids[0] == accepted_sup_id:
                correct += 1
            if accepted_sup_id in predicted_ids[:3]:
                top3_correct += 1
        
        total = len(training_data)
        print(f"\n📊 Training Data Validation:")
        print(f"   Precision@1: {correct/total*100:.1f}%")
        print(f"   Precision@3: {top3_correct/total*100:.1f}%")
    
    def predict(self, student, top_k=5):
        """
        Predict top K supervisors for a student
        Returns list of supervisors with similarity scores
        """
        if not self.trained:
            raise Exception("Model not trained yet!")
        
        # Extract student text features
        student_text = self.prepare_text_features(student)
        student_vector = self.vectorizer.transform([student_text])
        
        # Calculate cosine similarity with all supervisors
        similarities = cosine_similarity(student_vector, self.supervisor_vectors)[0]
        
        # Get top K indices
        top_indices = np.argsort(similarities)[::-1][:top_k]
        
        # Build recommendations
        recommendations = []
        for idx in top_indices:
            supervisor = self.supervisor_profiles[idx].copy()
            supervisor['similarity_score'] = float(similarities[idx])
            supervisor['match_percentage'] = int(similarities[idx] * 100)
            recommendations.append(supervisor)
        
        return recommendations
    
    def save(self, filepath='custom_model.pkl'):
        """Save trained model to disk"""
        if not self.trained:
            raise Exception("Cannot save untrained model!")
        
        model_data = {
            'vectorizer': self.vectorizer,
            'supervisor_profiles': self.supervisor_profiles,
            'supervisor_vectors': self.supervisor_vectors
        }
        
        with open(filepath, 'wb') as f:
            pickle.dump(model_data, f)
        print(f"💾 Model saved to {filepath}")
    
    def load(self, filepath='custom_model.pkl'):
        """Load trained model from disk"""
        with open(filepath, 'rb') as f:
            model_data = pickle.load(f)
        
        self.vectorizer = model_data['vectorizer']
        self.supervisor_profiles = model_data['supervisor_profiles']
        self.supervisor_vectors = model_data['supervisor_vectors']
        self.trained = True
        print(f"📂 Model loaded from {filepath}")


def load_data_from_json():
    """Load supervisor and student data from JSON files"""
    supervisors = []
    students = []
    
    # Try to load from benchmark data
    if os.path.exists('benchmark_data.json'):
        with open('benchmark_data.json', 'r') as f:
            data = json.load(f)
            supervisors = data.get('supervisors', [])
            students = data.get('students', [])
    
    return supervisors, students


def main():
    """Train and save the custom model"""
    print("="*60)
    print("🚀 Custom Recommendation Model Training")
    print("="*60)
    
    # Load data
    supervisors, students = load_data_from_json()
    
    if not supervisors:
        print("❌ No supervisor data found!")
        print("   Please ensure benchmark_data.json exists with supervisor data")
        return
    
    print(f"📊 Loaded {len(supervisors)} supervisors and {len(students)} students")
    
    # Create and train model
    model = CustomRecommendationModel()
    
    # If we have students with expected supervisors, use as training data
    training_data = []
    if students:
        for student in students:
            if 'expected_supervisor' in student:
                training_data.append((student, student['expected_supervisor']))
    
    model.train(supervisors, training_data if training_data else None)
    
    # Save model
    model.save('custom_model.pkl')
    
    print("\n✅ Training complete!")
    print("   Model saved as 'custom_model.pkl'")
    print("   Use this model to compare with AI recommendations")
    
    # Test prediction
    if students:
        print("\n🧪 Testing prediction on first student:")
        test_student = students[0]
        print(f"   Student: {test_student.get('name', 'Unknown')}")
        print(f"   Interests: {test_student.get('interest', 'N/A')}")
        
        predictions = model.predict(test_student, top_k=3)
        print(f"\n   Top 3 Recommendations:")
        for i, pred in enumerate(predictions, 1):
            print(f"   {i}. {pred.get('name')} - {pred['match_percentage']}% match")


if __name__ == '__main__':
    main()
