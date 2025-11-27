"""
Compare AI (Gemma 3:1b) recommendations vs Custom Trained Model
This validates if both models agree on which supervisors to recommend
"""

import json
import os
import pickle
import requests
from train_model import CustomRecommendationModel


def load_custom_model():
    """Load the trained custom model"""
    if not os.path.exists('custom_model.pkl'):
        print("❌ Custom model not found! Please run train_model.py first")
        return None
    
    model = CustomRecommendationModel()
    model.load('custom_model.pkl')
    return model


def get_ai_recommendations(student, supervisors):
    """Get recommendations from AI (Gemma 3:1b) via Flask backend"""
    try:
        response = requests.post(
            'http://localhost:5000/recommend',
            json={
                'student': student,
                'supervisors': supervisors
            },
            timeout=30
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"❌ AI API error: {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ AI API call failed: {str(e)}")
        return None


def calculate_agreement(ai_recs, custom_recs, top_k=3):
    """
    Calculate agreement between AI and custom model
    Returns overlap percentage and matched supervisors
    """
    if not ai_recs or not custom_recs:
        return 0, []
    
    ai_ids = [rec.get('id') for rec in ai_recs[:top_k] if rec.get('id')]
    custom_ids = [rec.get('id') for rec in custom_recs[:top_k] if rec.get('id')]
    
    # Calculate overlap
    matched = set(ai_ids) & set(custom_ids)
    total = len(set(ai_ids) | set(custom_ids))
    
    agreement = len(matched) / total * 100 if total > 0 else 0
    
    return agreement, list(matched)


def compare_recommendations(student, supervisors, custom_model):
    """Compare AI and Custom model for one student"""
    student_name = student.get('name', 'Unknown')
    student_interests = student.get('interest', 'N/A')
    
    print(f"\n{'='*80}")
    print(f"👤 Student: {student_name}")
    print(f"   Interests: {student_interests}")
    print(f"{'='*80}")
    
    # Get AI recommendations
    print("\n🤖 Getting AI (Gemma 3:1b) recommendations...")
    ai_result = get_ai_recommendations(student, supervisors)
    
    if ai_result and 'recommendations' in ai_result:
        ai_recs = ai_result['recommendations']
        print(f"   ✅ AI returned {len(ai_recs)} recommendations")
        print("\n   AI Top 3:")
        for i, rec in enumerate(ai_recs[:3], 1):
            print(f"   {i}. {rec.get('name', 'Unknown')} - {rec.get('matchPercentage', 0)}%")
    else:
        ai_recs = []
        print("   ❌ AI returned no recommendations")
    
    # Get Custom model recommendations
    print("\n🎓 Getting Custom Model recommendations...")
    custom_recs = custom_model.predict(student, top_k=5)
    print(f"   ✅ Custom model returned {len(custom_recs)} recommendations")
    print("\n   Custom Model Top 3:")
    for i, rec in enumerate(custom_recs[:3], 1):
        print(f"   {i}. {rec.get('name', 'Unknown')} - {rec.get('match_percentage', 0)}%")
    
    # Calculate agreement
    agreement, matched_ids = calculate_agreement(ai_recs, custom_recs, top_k=3)
    
    print(f"\n📊 AGREEMENT ANALYSIS:")
    print(f"   Agreement Score: {agreement:.1f}%")
    
    if matched_ids:
        print(f"   ✅ Both models agreed on {len(matched_ids)} supervisor(s):")
        for sup in supervisors:
            if sup.get('id') in matched_ids:
                print(f"      - {sup.get('name', 'Unknown')}")
    else:
        print(f"   ❌ No agreement between models")
    
    return {
        'student': student_name,
        'ai_recommendations': ai_recs[:3],
        'custom_recommendations': custom_recs[:3],
        'agreement_score': agreement,
        'matched_supervisors': len(matched_ids)
    }


def main():
    """Run comparison between AI and Custom model"""
    print("="*80)
    print("🔬 Model Comparison: AI (Gemma 3:1b) vs Custom Trained Model")
    print("="*80)
    
    # Load data
    if not os.path.exists('benchmark_data.json'):
        print("❌ benchmark_data.json not found!")
        return
    
    with open('benchmark_data.json', 'r') as f:
        data = json.load(f)
    
    supervisors = data.get('supervisors', [])
    students = data.get('students', [])
    
    print(f"\n📊 Dataset: {len(students)} students, {len(supervisors)} supervisors")
    
    # Load custom model
    custom_model = load_custom_model()
    if not custom_model:
        print("\n⚠️  Run 'python train_model.py' first to create the custom model!")
        return
    
    # Compare for all students
    results = []
    total_agreement = 0
    
    for i, student in enumerate(students, 1):
        print(f"\n\n{'#'*80}")
        print(f"# STUDENT {i}/{len(students)}")
        print(f"{'#'*80}")
        
        result = compare_recommendations(student, supervisors, custom_model)
        results.append(result)
        total_agreement += result['agreement_score']
    
    # Summary
    avg_agreement = total_agreement / len(students) if students else 0
    
    print("\n\n" + "="*80)
    print("📈 FINAL SUMMARY")
    print("="*80)
    print(f"\nTotal Students Tested: {len(students)}")
    print(f"Average Agreement Score: {avg_agreement:.1f}%")
    
    # Count high agreement cases
    high_agreement = sum(1 for r in results if r['agreement_score'] >= 60)
    print(f"High Agreement Cases (≥60%): {high_agreement}/{len(students)} ({high_agreement/len(students)*100:.1f}%)")
    
    # Save results
    with open('comparison_results.json', 'w') as f:
        json.dump({
            'summary': {
                'total_students': len(students),
                'average_agreement': avg_agreement,
                'high_agreement_count': high_agreement
            },
            'detailed_results': results
        }, f, indent=2)
    
    print(f"\n💾 Detailed results saved to comparison_results.json")
    
    # Interpretation
    print(f"\n🎯 INTERPRETATION:")
    if avg_agreement >= 70:
        print(f"   ✅ EXCELLENT: Both models agree strongly ({avg_agreement:.1f}%)")
        print(f"      Your custom model validates the AI recommendations!")
    elif avg_agreement >= 50:
        print(f"   ✓ GOOD: Moderate agreement ({avg_agreement:.1f}%)")
        print(f"      Models show reasonable consistency")
    else:
        print(f"   ⚠️  LOW: Models disagree significantly ({avg_agreement:.1f}%)")
        print(f"      Consider reviewing the training data or AI prompts")


if __name__ == '__main__':
    main()
