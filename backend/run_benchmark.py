import json
import requests
import time
import sys

# Configuration
API_URL = "http://localhost:5000/recommend"
DATA_FILE = "benchmark_data.json"

def run_benchmark():
    print(f"🚀 Starting Benchmark for Gemma 3:1b...")
    
    # Load data
    try:
        with open(DATA_FILE, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: {DATA_FILE} not found.")
        return

    supervisors = data['supervisors']
    students = data['students']
    
    total_students = len(students)
    top1_hits = 0
    top3_hits = 0
    
    print(f"📊 Loaded {len(supervisors)} supervisors and {total_students} students.")
    print("-" * 60)
    print(f"{'Student':<20} | {'Expected':<20} | {'Actual Top 1':<20} | {'Rank':<4} | {'Running Accuracy'}")
    print("-" * 110)

    for idx_student, student in enumerate(students):
        payload = {
            "student": student,
            "supervisors": supervisors
        }
        
        try:
            # Measure latency
            start_time = time.time()
            response = requests.post(API_URL, json=payload)
            latency = time.time() - start_time
            
            if response.status_code == 200:
                result = response.json()
                recommendations = result.get('recommendations', [])
                
                # Find rank of expected supervisor
                expected_id = student['expected_top_match']
                actual_rank = -1
                actual_top_name = "None"
                
                if recommendations:
                    actual_top_name = recommendations[0].get('name', 'Unknown')
                    
                    for idx, rec in enumerate(recommendations):
                        # We need to match by ID, but the API might not return the ID directly 
                        # if it's not in the supervisor object passed back.
                        # Let's assume the API returns the full supervisor object we sent.
                        if rec.get('id') == expected_id:
                            actual_rank = idx + 1
                            break
                
                # Update metrics
                rank_display = str(actual_rank) if actual_rank != -1 else "Not found"
                
                if actual_rank == 1:
                    top1_hits += 1
                    icon = "✅"
                elif actual_rank <= 3 and actual_rank != -1:
                    top3_hits += 1
                    icon = "⚠️"
                else:
                    icon = "❌"
                
                # Calculate running accuracy
                processed_count = idx_student + 1
                current_p1 = (top1_hits / processed_count) * 100
                current_p3 = ((top1_hits + top3_hits) / processed_count) * 100 # top3_hits in loop tracks 2nd/3rd. 
                # Wait, let's correct the logic. 
                # In the original code:
                # if actual_rank == 1: top1_hits += 1
                # elif actual_rank <= 3: top3_hits += 1
                # So top3_hits ONLY contained ranks 2 and 3.
                # So P@3 = (top1 + top3) / total.
                
                print(f"{icon} {student['name']:<18} | {expected_id:<20} | {actual_top_name:<20} | {rank_display:<4} | P@1: {current_p1:.1f}% | P@3: {current_p3:.1f}%")

                    
            else:
                print(f"❌ Error for {student['name']}: API returned {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print("❌ Error: Could not connect to backend. Is it running?")
            sys.exit(1)
        except Exception as e:
            print(f"❌ Error processing {student['name']}: {e}")

    # Calculate final metrics
    precision_at_1 = (top1_hits / total_students) * 100
    precision_at_3 = ((top1_hits + top3_hits) / total_students) * 100 # Note: top3_hits in loop only counted 2nd and 3rd place.
    # Wait, my logic above for top3_hits was "elif actual_rank <= 3". 
    # So top1_hits are NOT included in top3_hits variable in the loop.
    # So (top1 + top3) is correct for "Precision@3" (meaning hit within top 3).
    
    print("-" * 110)
    print("🏆 BENCHMARK RESULTS")
    print("-" * 110)
    print(f"Total Students: {total_students}")
    print(f"Precision@1:    {precision_at_1:.1f}%  (Top recommendation was correct)")
    print(f"Precision@3:    {precision_at_3:.1f}%  (Correct supervisor in top 3)")
    print("-" * 60)
    
    if precision_at_1 >= 70:
        print("✅ PASSED: System meets accuracy requirements.")
    else:
        print("⚠️ WARNING: Accuracy is below 70%. Tuning may be required.")

if __name__ == "__main__":
    run_benchmark()
