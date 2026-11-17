# Voting app API: counts page visits and yes/no votes, stored in DynamoDB.
#
# Run by gunicorn in the container (not `python api.py`). gunicorn imports this
# module and looks for the Flask object by name, e.g. `gunicorn api:app`, so
# this file needs NO `if __name__ == "__main__": app.run(...)` block.

import os

import boto3
from botocore.config import Config
from flask import Flask, jsonify, request

# The Flask app. gunicorn finds it by this name ("api:app").
app = Flask(__name__)

# DynamoDB table. DYNAMODB_ENDPOINT is only set for DynamoDB Local; when it's unset
# (None), boto3 talks to the real AWS service. Created once per gunicorn worker.
# Short timeouts and few retries, so a DynamoDB problem makes /readyz fail in
# seconds instead of hanging.
resource = boto3.resource(
    'dynamodb',
    endpoint_url=os.environ.get('DYNAMODB_ENDPOINT'),
    config=Config(connect_timeout=2, read_timeout=2, retries={'max_attempts': 2}),
)
table = resource.Table(os.environ.get('TABLE_NAME', 'votes'))

# Counter keys. Table layout: partition key "pk" (string), counter attribute "cnt".
COUNTERS = ['visits', 'yes', 'no']


def increment_counter(key):
    if key not in COUNTERS:
        raise ValueError(f"Invalid counter key: {key}")
    # ADD is atomic (no read-then-write race) and creates the item if it's missing.
    table.update_item(
        Key={'pk': key},
        UpdateExpression='ADD cnt :inc',
        ExpressionAttributeValues={':inc': 1},
    )


def read_all_counts():
    counts = {}
    for key in COUNTERS:
        response = table.get_item(Key={'pk': key})
        # No 'Item' means the counter hasn't been created yet: 0.
        # DynamoDB returns Decimal; int() so jsonify can serialize it.
        counts[key] = int(response['Item']['cnt']) if 'Item' in response else 0
    return counts


@app.route('/api/visit', methods=['POST'])
def visit():
    increment_counter('visits')
    return jsonify(read_all_counts()), 200


@app.route('/api/vote', methods=['POST'])
def vote():
    # silent=True: a missing or non-JSON body gives None instead of an error page.
    data = request.get_json(silent=True)
    choice = data.get('choice') if isinstance(data, dict) else None
    if choice not in ('yes', 'no'):
        return jsonify({'error': "choice must be 'yes' or 'no'"}), 400
    increment_counter(choice)
    return jsonify(read_all_counts()), 200


@app.route('/api/stats', methods=['GET'])
def stats():
    return jsonify(read_all_counts()), 200


# Liveness: is the process alive? Never touches DynamoDB, so a DynamoDB outage
# doesn't make Kubernetes restart every pod.
@app.route('/healthz', methods=['GET'])
def healthz():
    return 'ok', 200


# Readiness: can this pod serve traffic? Failing takes the pod out of the Service
# (no restart) until DynamoDB is reachable again.
@app.route('/readyz', methods=['GET'])
def readyz():
    try:
        table.get_item(Key={'pk': 'visits'})
        return 'ready', 200
    except Exception:
        return 'not ready', 503
