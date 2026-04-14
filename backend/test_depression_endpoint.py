import asyncio
import httpx
import json
import time

async def test_endpoint():
    print("Testing /jobs/depression endpoint...")
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Dummy questionnaire data mimicking Flutter payload
        q_data = {
            "depression_q_0_text": "I have been feeling very sad and low lately. My mood is generally down.",
            "depression_q_1_text": "Yes, I have definitely lost interest in my hobbies like football and gaming.",
            "depression_q_2_text": "I haven't been sleeping well at all, waking up multiple times.",
            "depression_q_3_text": "My energy is very low, I feel tired all the time.",
            "condition": "depression"
        }
        
        # Multipart form data
        data = {
            "questionnaire_data": json.dumps(q_data)
        }
        
        try:
            response = await client.post("http://127.0.0.1:8000/jobs/depression", data=data)
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.json()}")
            
            if response.status_code == 200:
                job_id = response.json().get("job_id")
                print(f"\nPolling job status for {job_id}...")
                
                for i in range(10):
                    time.sleep(2)
                    status_res = await client.get(f"http://127.0.0.1:8000/jobs/{job_id}")
                    status_data = status_res.json()
                    status = status_data.get("status")
                    print(f"Attempt {i+1}: {status}")
                    
                    if status in ["completed", "failed"]:
                        if status == "completed":
                            res = await client.get(f"http://127.0.0.1:8000/jobs/{job_id}/result")
                            print(f"\nFinal Result:\n{json.dumps(res.json(), indent=2)}")
                        else:
                            print(f"\nError: {status_data.get('error')}")
                        break
                        
        except Exception as e:
            print(f"Connection failed: {e}. Make sure backend is running.")

if __name__ == "__main__":
    asyncio.run(test_endpoint())
