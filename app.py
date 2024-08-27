from flask import Flask, request, jsonify
import joblib

app = Flask(__name__)

# Load model
model = joblib.load('./model/model.joblib')
@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json(force=True)
    prediction = model.predict([data['features']])
    return jsonify(prediction=prediction.tolist())

if __name__ == '__main__':
    app.run(port=5000, debug=True)
