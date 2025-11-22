import requests
import json
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Ollama API configuration
OLLAMA_API_URL = os.getenv('OLLAMA_API_URL', 'http://localhost:11434/api/generate')
OLLAMA_MODEL = os.getenv('OLLAMA_MODEL', 'gemma3:1b')

@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({"status": "ok", "model": OLLAMA_MODEL})

@app.route('/recommend', methods=['POST'])
def recommend_supervisors():
    """Endpoint to recommend supervisors based on student profile"""
    try:
        data = request.json
        student = data.get('student', {})
        supervisors = data.get('supervisors', [])
        
        print(f"\n{'='*60}")
        print(f"📥 Received recommendation request")
        print(f"👨‍🎓 Student interests: {student.get('interest', 'N/A')}")
        print(f"⚡ Student skills: {student.get('skills', 'N/A')}")
        print(f"👨‍🏫 Number of supervisors: {len(supervisors)}")
        
        if not student or not supervisors:
            print("❌ Missing student or supervisors data")
            return jsonify({"error": "Missing student or supervisors data"}), 400
        
        # Format the prompt for Ollama
        prompt = format_prompt(student, supervisors)
        print(f"📝 Prompt length: {len(prompt)} characters")
        
        # Get recommendations from Ollama
        recommendations = get_ollama_recommendations(prompt)
        
        # Process and enhance the recommendations
        processed_recommendations = process_recommendations(recommendations, supervisors)
        
        print(f"✅ Returning {len(processed_recommendations)} processed recommendations")
        print(f"{'='*60}\n")
        
        return jsonify({
            "recommendations": processed_recommendations,
            "ai_explanation": recommendations.get("explanation", "")
        })
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

def format_prompt(student, supervisors):
    """Format a prompt for Ollama based on student and supervisor data"""
    
    # Extract student information
    student_interests = student.get('interest', [])
    if isinstance(student_interests, str):
        student_interests = [i.strip() for i in student_interests.split(',') if i.strip()]
    
    student_skills = student.get('skills', [])
    if isinstance(student_skills, str):
        student_skills = [s.strip() for s in student_skills.split(',') if s.strip()]
    
    # Create supervisor descriptions
    supervisor_descriptions = []
    for i, supervisor in enumerate(supervisors):
        specialization = supervisor.get('specialization', '')
        preference_areas = supervisor.get('preferenceAreas', [])
        if isinstance(preference_areas, str):
            preference_areas = [p.strip() for p in preference_areas.split(',') if p.strip()]
        
        project_history = supervisor.get('projectHistoryCategories', [])
        if isinstance(project_history, str):
            project_history = [p.strip() for p in project_history.split(',') if p.strip()]
            
        supervisor_descriptions.append(
            f"Supervisor {i+1}: {supervisor.get('name', 'Unknown')}\n"
            f"- Specialization: {specialization}\n"
            f"- Preference Areas: {', '.join(preference_areas)}\n"
            f"- Project History: {', '.join(project_history)}\n"
        )
    
    # Construct the full prompt with clear JSON instructions
    prompt = f"""You are an academic advisor. Match students with thesis supervisors.

STUDENT:
Interests: {', '.join(student_interests) if student_interests else 'Not specified'}
Skills: {', '.join(student_skills) if student_skills else 'Not specified'}

SUPERVISORS:
{''.join(supervisor_descriptions)}

TASK: Rank the top 3-5 supervisors for this student based on matching interests and skills.

IMPORTANT: Respond ONLY with valid JSON in this exact format:
{{
  "supervisorRanking": [
    {{"supervisorNumber": 1, "matchReason": "Shares interest in AI and has ML expertise"}},
    {{"supervisorNumber": 2, "matchReason": "Python skills match project requirements"}}
  ],
  "explanation": "These supervisors match the student's technical interests"
}}

Do not include any text before or after the JSON. Start with {{ and end with }}.
"""
    return prompt

def get_ollama_recommendations(prompt):
    """Send a prompt to Ollama and get recommendations"""
    try:
        print(f"🤖 Calling Ollama API with model: {OLLAMA_MODEL}")
        response = requests.post(
            OLLAMA_API_URL,
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False
            },
            timeout=60  # Increase timeout for LLM response
        )
        
        if response.status_code != 200:
            print(f"❌ Ollama API error: {response.status_code} - {response.text}")
            return {
                "supervisorRanking": [],
                "explanation": "Error communicating with AI model"
            }
        
        # Extract JSON from the response
        result = response.json()
        response_text = result.get('response', '')
        
        print(f"📝 Ollama response length: {len(response_text)} characters")
        print(f"📝 Ollama response preview: {response_text[:200]}...")
        
        # Try to extract JSON from the response text
        try:
            # Find JSON pattern in the response
            json_start = response_text.find('{')
            json_end = response_text.rfind('}') + 1
            
            if json_start >= 0 and json_end > json_start:
                json_str = response_text[json_start:json_end]
                parsed = json.loads(json_str)
                print(f"✅ Successfully parsed JSON with {len(parsed.get('supervisorRanking', []))} recommendations")
                return parsed
            else:
                print("⚠️ No JSON found in response, trying direct parse")
                # Fallback: try to parse the response as JSON directly
                return json.loads(response_text)
        except json.JSONDecodeError as je:
            print(f"⚠️ JSON decode error: {je}")
            print(f"⚠️ Attempting text parsing fallback")
            # If we can't extract JSON, create a simplified response
            result = process_text_response(response_text)
            print(f"📊 Text parsing found {len(result.get('supervisorRanking', []))} recommendations")
            return result
    
    except Exception as e:
        print(f"❌ Error calling Ollama API: {e}")
        import traceback
        traceback.print_exc()
        return {
            "supervisorRanking": [],
            "explanation": f"Error: {str(e)}"
        }

def process_text_response(text):
    """Process non-JSON response from Ollama into a structured format"""
    # Simple parsing for responses that didn't return valid JSON
    supervisors = []
    explanation = "AI recommended these supervisors based on matching interests and skills."
    
    lines = text.split('\n')
    current_sup = {}
    
    for line in lines:
        if line.startswith("Supervisor"):
            if current_sup and "supervisorNumber" in current_sup:
                supervisors.append(current_sup)
                current_sup = {}
            
            # Try to extract supervisor number
            try:
                sup_num = int(line.split()[1].rstrip(':'))
                current_sup = {"supervisorNumber": sup_num, "matchReason": ""}
            except:
                continue
        
        elif "match" in line.lower() and current_sup:
            current_sup["matchReason"] = line
    
    # Add the last supervisor if needed
    if current_sup and "supervisorNumber" in current_sup:
        supervisors.append(current_sup)
    
    return {
        "supervisorRanking": supervisors,
        "explanation": explanation
    }

def process_recommendations(ollama_response, supervisors):
    """Process Ollama's recommendations and combine with supervisor data"""
    rankings = ollama_response.get("supervisorRanking", [])
    
    print(f"📊 Processing {len(rankings)} rankings for {len(supervisors)} supervisors")
    
    # If no rankings, return empty list (will trigger fallback in Flutter)
    if not rankings:
        print("⚠️ No rankings provided by AI")
        return []
    
    # Map supervisor numbers to actual supervisors with their data
    processed_recommendations = []
    
    for idx, rank in enumerate(rankings, 1):
        sup_num = rank.get("supervisorNumber")
        print(f"  - Rank {idx}: Supervisor #{sup_num}")
        
        # Supervisor numbers are 1-indexed in the prompt but supervisors list is 0-indexed
        if sup_num and 1 <= sup_num <= len(supervisors):
            supervisor = supervisors[sup_num - 1]
            match_percentage = calculate_match_percentage(idx, len(rankings))
            processed_recommendations.append({
                **supervisor,
                "matchReason": rank.get("matchReason", "Good match based on interests and skills"),
                "aiRecommended": True,
                "matchPercentage": match_percentage,
                "confidenceScore": calculate_confidence_from_percentage(match_percentage),
            })
            print(f"    ✓ Added {supervisor.get('name', 'Unknown')} with {match_percentage}% match")
        else:
            print(f"    ✗ Invalid supervisor number: {sup_num}")
    
    return processed_recommendations

def calculate_confidence_from_percentage(percentage):
    """Calculate confidence level from match percentage"""
    if percentage >= 85:
        return "Excellent"
    elif percentage >= 75:
        return "Good"
    elif percentage >= 55:
        return "Fair"
    else:
        return "Low"

def calculate_match_percentage(position, total):
    """
    Calculate a match percentage based on position in recommendations
    Uses a more robust scoring system:
    - Rank 1: 85-95% (Excellent match)
    - Rank 2: 75-84% (Very good match)
    - Rank 3: 65-74% (Good match)
    - Rank 4: 55-64% (Fair match)
    - Rank 5+: 45-54% (Possible match)
    """
    if total <= 0:
        return 70
    
    if position == 1:
        return 95
    elif position == 2:
        return 85
    elif position == 3:
        return 75
    elif position == 4:
        return 65
    elif position == 5:
        return 55
    else:
        # For positions beyond 5, use declining scale
        percentage = max(45, 55 - ((position - 5) * 5))
        return percentage

def calculate_precision_at_k(recommendations, accepted_supervisor_id, k=5):
    """
    Calculate if accepted supervisor is in top K recommendations
    recommendations: list of supervisor IDs (ordered by rank)
    accepted_supervisor_id: supervisor ID that was actually accepted
    k: number of top recommendations to consider (default 5)
    Returns: 1 if hit, 0 if miss
    """
    if not recommendations or not accepted_supervisor_id:
        return 0
    
    top_k = recommendations[:k]
    return 1 if accepted_supervisor_id in top_k else 0

def overall_precision_at_k(all_data, k=5):
    """
    Calculate overall precision@K across all student recommendations
    all_data: list of dicts with 'recommendations' and 'accepted_supervisor_id'
    Returns: precision score between 0 and 1
    """
    if not all_data:
        return 0
    
    total = len(all_data)
    correct = sum(
        calculate_precision_at_k(d.get('recommendations', []), 
                                d.get('accepted_supervisor_id'), 
                                k)
        for d in all_data
    )
    return correct / total if total > 0 else 0

@app.route('/metrics/precision', methods=['POST'])
def calculate_precision_metrics():
    """
    Endpoint to calculate precision metrics for recommendations
    Expects JSON with array of recommendation outcomes
    """
    try:
        data = request.json
        outcomes = data.get('outcomes', [])
        k = data.get('k', 5)  # Default to top 5
        
        if not outcomes:
            return jsonify({"error": "No outcomes provided"}), 400
        
        print(f"\n{'='*60}")
        print(f"📊 Calculating Precision@{k} for {len(outcomes)} outcomes")
        
        # Calculate overall precision
        precision = overall_precision_at_k(outcomes, k)
        
        # Calculate by recommendation source
        ai_outcomes = [o for o in outcomes if o.get('source') == 'ai_rag']
        pattern_outcomes = [o for o in outcomes if o.get('source') == 'pattern_matching']
        
        ai_precision = overall_precision_at_k(ai_outcomes, k) if ai_outcomes else None
        pattern_precision = overall_precision_at_k(pattern_outcomes, k) if pattern_outcomes else None
        
        # Calculate hit rate per position
        position_hits = {}
        for outcome in outcomes:
            recs = outcome.get('recommendations', [])
            accepted = outcome.get('accepted_supervisor_id')
            if accepted in recs:
                position = recs.index(accepted) + 1
                position_hits[position] = position_hits.get(position, 0) + 1
        
        results = {
            'overall_precision_at_k': precision,
            'k': k,
            'total_samples': len(outcomes),
            'ai_rag_precision': ai_precision,
            'ai_rag_samples': len(ai_outcomes),
            'pattern_matching_precision': pattern_precision,
            'pattern_matching_samples': len(pattern_outcomes),
            'hits_by_position': position_hits,
            'percentage': f"{precision * 100:.1f}%"
        }
        
        print(f"✅ Overall Precision@{k}: {precision:.3f} ({precision*100:.1f}%)")
        if ai_precision is not None:
            print(f"   AI RAG: {ai_precision:.3f} ({ai_precision*100:.1f}%)")
        if pattern_precision is not None:
            print(f"   Pattern: {pattern_precision:.3f} ({pattern_precision*100:.1f}%)")
        print(f"{'='*60}\n")
        
        return jsonify(results)
        
    except Exception as e:
        print(f"❌ Error calculating precision: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug_mode = os.environ.get('FLASK_ENV') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug_mode)