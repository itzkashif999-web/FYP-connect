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
OLLAMA_MODEL = os.getenv('OLLAMA_MODEL', '3:1b')

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
        
        if not student or not supervisors:
            return jsonify({"error": "Missing student or supervisors data"}), 400
        
        # Format the prompt for Ollama
        prompt = format_prompt(student, supervisors)
        
        # Get recommendations from Ollama
        recommendations = get_ollama_recommendations(prompt)
        
        # Process and enhance the recommendations
        processed_recommendations = process_recommendations(recommendations, supervisors)
        
        return jsonify({
            "recommendations": processed_recommendations,
            "ai_explanation": recommendations.get("explanation", "")
        })
        
    except Exception as e:
        print(f"Error: {e}")
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
    
    # Construct the full prompt
    prompt = f"""You are an academic advisor specializing in matching students with the best thesis supervisors.

STUDENT PROFILE:
- Interests: {', '.join(student_interests)}
- Skills: {', '.join(student_skills)}

AVAILABLE SUPERVISORS:
{''.join(supervisor_descriptions)}

TASK: Recommend the best supervisors for this student based on how well their interests, specialization, and project history align with the student's interests and skills. 

Provide your recommendations in order of best match to least good match. For each recommendation, explain why they would be a good match, focusing on specific overlapping interests or complementary skills.

Format your response as a JSON array of objects with this structure:
{{
  "supervisorRanking": [
    {{ "supervisorNumber": 1, "matchReason": "explanation" }},
    {{ "supervisorNumber": 3, "matchReason": "explanation" }}
  ],
  "explanation": "brief overall explanation of your recommendations"
}}
"""
    return prompt

def get_ollama_recommendations(prompt):
    """Send a prompt to Ollama and get recommendations"""
    try:
        response = requests.post(
            OLLAMA_API_URL,
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False
            }
        )
        
        if response.status_code != 200:
            print(f"Ollama API error: {response.text}")
            return {
                "supervisorRanking": [],
                "explanation": "Error communicating with AI model"
            }
        
        # Extract JSON from the response
        result = response.json()
        response_text = result.get('response', '')
        
        # Try to extract JSON from the response text
        try:
            # Find JSON pattern in the response
            json_start = response_text.find('{')
            json_end = response_text.rfind('}') + 1
            
            if json_start >= 0 and json_end > json_start:
                json_str = response_text[json_start:json_end]
                return json.loads(json_str)
            else:
                # Fallback: try to parse the response as JSON directly
                return json.loads(response_text)
        except json.JSONDecodeError:
            # If we can't extract JSON, create a simplified response
            return process_text_response(response_text)
    
    except Exception as e:
        print(f"Error calling Ollama API: {e}")
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
    
    # Map supervisor numbers to actual supervisors with their data
    processed_recommendations = []
    
    for rank in rankings:
        sup_num = rank.get("supervisorNumber")
        # Supervisor numbers are 1-indexed in the prompt but supervisors list is 0-indexed
        if 1 <= sup_num <= len(supervisors):
            supervisor = supervisors[sup_num - 1]
            processed_recommendations.append({
                **supervisor,
                "matchReason": rank.get("matchReason", ""),
                "aiRecommended": True,
                "matchPercentage": calculate_match_percentage(sup_num, len(rankings)),
            })
    
    return processed_recommendations

def calculate_match_percentage(position, total):
    """Calculate a match percentage based on position in recommendations"""
    if total <= 1:
        return 95
    
    # Calculate percentage, first position gets highest score
    base_percentage = 95
    step = 10
    percentage = base_percentage - ((position - 1) * step)
    
    # Ensure percentage is between 50 and 95
    return max(50, min(95, percentage))

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug_mode = os.environ.get('FLASK_ENV') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug_mode)