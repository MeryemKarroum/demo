import numpy as np
import tensorflow as tf
import joblib

# Load model and scaler
model = tf.keras.models.load_model("tata_model_rnn.h5")
scaler = joblib.load("scaler.pkl")

# Create a dummy input sequence
dummy_sequence = np.random.rand(60).reshape(-1, 1)  # Random 60 values
scaled_sequence = scaler.transform(dummy_sequence)
input_sequence = scaled_sequence.reshape(1, 60, 1)

# Predict
prediction = model.predict(input_sequence)
print("Raw Prediction:", prediction)
original_value = scaler.inverse_transform([[prediction[0][0]]])
print("Inverse Transformed Prediction:", original_value)
