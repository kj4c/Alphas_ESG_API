import json
import sys
import os

# Add parent directory to sys.path so imports work
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from handler import lambda_handler  # <-- replace with your real filename (no .py)

# Simulate what AWS passes in a real event
event = {
    "body": json.dumps({
        "id": "76d3b838-5880-4320-b42f-8bd8273ab6a0",
        "property_type": "HOUSE",
        "suburb": "North Rocks"
    }),  # 👈 this simulates what API Gateway sends
}

# Simulate a Lambda context object (optional if you don't use it)
context = {}

# Run the lambda locally
response = lambda_handler(event, context)

# Pretty print the result
print(json.dumps(response, indent=2))