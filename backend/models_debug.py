import requests
import numpy as np
import json
import sys

BASE_URL = "http://localhost:8000"
# Replace with your actual key if required by the Security header
HEADERS = {"X-API-Key": "your_key_here", "Content-Type": "application/json"}

# ==============================
# 1. FIX SERIALIZATION (NumpyEncoder)
# ==============================
class NumpyEncoder(json.JSONEncoder):
    """ Custom encoder for numpy types to prevent 'int64 not JSON serializable' errors """
    def default(self, obj):
        if isinstance(obj, (np.int_, np.intc, np.intp, np.int8,
                            np.int16, np.int32, np.int64, np.uint8,
                            np.uint16, np.uint32, np.uint64)):
            return int(obj)
        elif isinstance(obj, (np.float_, np.float16, np.float32, np.float64)):
            return float(obj)
        elif isinstance(obj, (np.ndarray,)):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)

def safe_request(method, endpoint, payload=None):
    url = f"{BASE_URL}{endpoint}"
    try:
        # Use json.dumps with the custom encoder to ensure valid JSON
        data = json.dumps(payload, cls=NumpyEncoder) if payload else None
        response = requests.request(method, url, data=data, headers=HEADERS, timeout=10)
        
        print(f"\n[HTTP {response.status_code}] {method} {endpoint}")
        if response.status_code != 200:
            print(f"⚠️ ERROR: {response.text}")
            return None
        
        return response.json()
    except Exception as e:
        print(f"❌ Connection Failed to {url}: {e}")
        return None

# ==============================
# 2. DIAGNOSTIC TESTS
# ==============================

def test_model_sensitivity(name, endpoint, test_cases, confidence_keys=["confidence", "probability", "avg_confidence"]):
    print(f"\n{'='*20} TESTING {name} {'='*20}")
    results = []
    
    for label, payload in test_cases:
        res = safe_request("POST", endpoint, payload)
        if res:
            # Extract confidence using multiple possible keys
            conf = next((res.get(k) for k in confidence_keys if k in res), None)
            pred = res.get("prediction", "N/A")
            
            print(f"CASE [{label}]: Pred={pred}, Conf={conf}")
            print(f"RAW: {json.dumps(res, indent=2)}")
            
            if conf is not None:
                results.append(float(conf))
        else:
            print(f"CASE [{label}]: FAILED")

    if results:
        variance = np.var(results)
        print(f"\n📊 {name} VARIANCE: {variance:.8f}")
        if variance < 1e-5:
            avg = np.mean(results)
            if 0.48 <= avg <= 0.52:
                print(f"🚨 ALERT: {name} STUCK AT MIDPOINT (Mean: {avg:.4f})")
            else:
                print(f"🚨 ALERT: {name} OUTPUT IS CONSTANT (Value: {avg:.4f})")
    else:
        print(f"❌ No valid results for {name}")

def run_debug():
    # ASD - Testing for Score-based Fallback pattern (sum/10)
    asd_cases = [
        ("0/10 Yes", {"answers": [0]*10}),
        ("7/10 Yes", {"answers": [1]*7 + [0]*3}),
        ("10/10 Yes", {"answers": [1]*10})
    ]
    test_model_sensitivity("ASD", "/asd/text/predict", asd_cases)

    # ADHD - Testing for Midpoint Trap
    adhd_cases = [
        ("Negative", {"chat_q_0_text": "Never", "age": 25}),
        ("Positive", {"chat_q_0_text": "Always", "age": 25})
    ]
    test_model_sensitivity("ADHD", "/predict/adhd/behavior", adhd_cases)

    # Depression - Testing for potential async or routing failure
    dep_cases = [
        ("Questionnaire", {"depression_q_0_text": "Sad", "depression_q_1_text": "Tired"})
    ]
    # Note: Check if endpoint is /predict/depression or /jobs/depression
    test_model_sensitivity("Depression", "/jobs/depression", dep_cases)

if __name__ == "__main__":
    run_debug()
