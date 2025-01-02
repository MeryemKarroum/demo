import logging
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
from PIL import Image
import io
from sklearn.preprocessing import MinMaxScaler
import tensorflow as tf
import pandas as pd
import joblib

from sklearn.preprocessing import MinMaxScaler
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  
)

# Load models
fruit_model = tf.keras.models.load_model("FruitsCNN2.h5")
fashion_model = tf.keras.models.load_model("fashion.h5")  # Updated model name for ANN
fruit_ann_model = tf.keras.models.load_model("ANNfruits_vegetables2.h5")
tata_rnn_model = tf.keras.models.load_model("tata_model_rnn.h5")
lstm_model=tf.keras.models.load_model("LSTM.h5")
# Define class labels
#fruit_labels = ["apple", "banana", "orange"]

fruit_labels = ["apple", "banana", "cherry", "chickoo", "grape", "kiwi", "mango", "orange", "pear", "strawberry"]
fashion_labels = [
    "T-shirt/top",
    "Trouser",
    "Pullover",
    "Dress",
    "Coat",
    "Sandal",
    "Shirt",
    "Sneaker",
    "Bag",
    "Ankle boot",
]

CLASSES = [
    "apple", "banana", "beetroot", "bell pepper", "cabbage", "capsicum", "carrot",
    "cauliflower", "chilli pepper", "corn", "cucumber", "eggplant", "garlic", "ginger",
    "grapes", "jalepino", "kiwi", "lemon", "letuce", "mango", "onion", "orange",
    "paprika", "pear", "peas", "pineapple", "pomegranate", "potato", "raddish",
    "soy beans", "spinach", "sweetcorn", "sweetpotato", "tomato", "turnip", "watermelon"
]

@app.post("/classify/fruit")
async def classify_fruit(file: UploadFile = File(...)):
    # Read and preprocess the image
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))

    # Convert image to RGB to remove alpha channel (if present)
    image = image.convert("RGB")

    image = image.resize((128, 128))  # Resize to (32, 32) for fruit model
    image_array = np.array(image) / 255.0  # Normalize the image
    
    # Add batch dimension
    image_array = np.expand_dims(image_array, axis=0)

    # Make prediction
    predictions = fruit_model.predict(image_array)
    predicted_class = fruit_labels[np.argmax(predictions[0])]
    confidence = float(np.max(predictions[0]))

    return {"type": "fruit", "class": predicted_class, "confidence": confidence}


@app.post("/classify/fashion")
async def classify_fashion(file: UploadFile = File(...)):
    # Read and preprocess the image
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))
    image = image.convert("L")  # Convert to grayscale
    image = image.resize((28, 28))  # Resize to (28, 28) for the fashion model
    image_array = np.array(image) / 255.0  # Normalize the image

    # Reshape the image to (1, 28, 28) to match the model's input shape
    image_array = np.expand_dims(image_array, axis=0)

    # Make prediction
    predictions = fashion_model.predict(image_array)
    predicted_class = fashion_labels[np.argmax(predictions[0])]
    confidence = float(np.max(predictions[0]))

    return {"type": "fashion", "class": predicted_class, "confidence": confidence}


@app.post("/classify/fruit/ann")
async def classify_fruit_ann(file: UploadFile = File(...)):
    """Classify fruit using the ANN model."""
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))

    # Convert image to RGB and preprocess for ANN model
    image = image.convert("RGB")
    image = image.resize((28, 28))  # Resize for ANN input
    image_array = np.array(image) / 255.0  # Normalize image

    # Add batch dimension
    image_array = np.expand_dims(image_array, axis=0)

    # Predict using ANN model
    predictions = fruit_ann_model.predict(image_array)
    predicted_class = CLASSES[np.argmax(predictions[0])]
    confidence = float(np.max(predictions[0]))

    return {"type": "fruit_ann", "class": predicted_class, "confidence": confidence}


@app.post("/predict/rnn")
async def predict_rnn(file: UploadFile = File(...)):
    try:
        # Load scaler and model
        logging.debug("Loading scaler and model...")
        scaler = joblib.load("scaler.pkl")  # Ensure this matches the training scaler
        tata_rnn_model = tf.keras.models.load_model("tata_model_rnn.h5")
    except Exception as e:
        logging.error(f"Failed to load resources: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to load resources: {e}")

    # Read the uploaded file
    try:
        contents = await file.read()
        csv_data = pd.read_csv(io.BytesIO(contents))
        logging.debug(f"Uploaded CSV Data: \n{csv_data.head()}")
        logging.debug(f"CSV Data Shape: {csv_data.shape}")
        logging.debug(f"CSV Data Length: {len(csv_data)}")
        logging.debug(f"CSV Columns: {csv_data.columns}")
    except Exception as e:
        logging.error(f"Failed to read CSV file: {e}")
        raise HTTPException(status_code=400, detail=f"Failed to read CSV file: {e}")

    # Validate the file structure
    if csv_data.shape[1] != 1:
        logging.error("Uploaded file must contain exactly one column of sequence data.")
        raise HTTPException(status_code=400, detail="Uploaded file must contain exactly one column of sequence data.")
    
    if len(csv_data) < 60:
        logging.error(f"Uploaded file must contain at least 60 values, but it contains {len(csv_data)} rows.")
        raise HTTPException(status_code=400, detail=f"Sequence data must contain at least 60 values, but got {len(csv_data)} rows.")

    try:
        # Preprocess data
        sequence_data = csv_data.values.astype(float)  # Ensure data is float
        logging.debug(f"Sequence Data: {sequence_data}")
        logging.debug(f"Sequence Data Length: {len(sequence_data)}")

        scaled_data = scaler.transform(sequence_data)  # Scale using the same scaler
        logging.debug(f"Scaled Data: {scaled_data}")

        # Prepare input sequence
        input_sequence = scaled_data.reshape(1, 60, 1)
        logging.debug(f"Input Sequence Shape: {input_sequence.shape}")

        # Predict using the model
        prediction = tata_rnn_model.predict(input_sequence)
        logging.debug(f"Raw Prediction: {prediction}")

        if prediction is None or len(prediction) == 0:
            logging.error("Model returned no valid output.")
            raise HTTPException(status_code=500, detail="Model returned no valid output.")

        # Inverse transform the prediction to the original scale
        predicted_value = scaler.inverse_transform([[prediction[0][0]]])
        logging.debug(f"Predicted Value: {predicted_value}")

        # Ensure predicted_value is serializable
        predicted_value = predicted_value[0][0]  # Flatten the array to a single float

        return {"predicted_value": predicted_value}
    except Exception as e:
        logging.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {e}")


@app.post("/predict/lstm")
async def predict_lstm(file: UploadFile = File(...)):
    try:
        # Load scaler and model
        scaler = joblib.load("scaler.pkl")  # Ensure this matches the training scaler
        lstm_model = tf.keras.models.load_model("LSTM.h5")  # Load the LSTM model
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load resources: {e}")

    # Read the uploaded file
    try:
        contents = await file.read()
        csv_data = pd.read_csv(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to read CSV file: {e}")

    # Validate the file structure
    if csv_data.shape[1] != 1:
        raise HTTPException(status_code=400, detail="Uploaded file must contain exactly one column of sequence data.")
    
    if len(csv_data) < 60:
        raise HTTPException(status_code=400, detail=f"Sequence data must contain at least 60 values, but got {len(csv_data)} rows.")

    try:
        # Preprocess data
        sequence_data = csv_data.values.astype(float)  # Ensure data is float

        scaled_data = scaler.transform(sequence_data)  # Scale using the same scaler

        # Prepare input sequence
        input_sequence = scaled_data.reshape(1, 60, 1)

        # Predict using the model
        prediction = lstm_model.predict(input_sequence)

        if prediction is None or len(prediction) == 0:
            raise HTTPException(status_code=500, detail="Model returned no valid output.")

        # Inverse transform the prediction to the original scale
        predicted_value = scaler.inverse_transform([[prediction[0][0]]])

        # Ensure predicted_value is serializable
        predicted_value = predicted_value[0][0]  # Flatten the array to a single float

        return {"predicted_value": predicted_value}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {e}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
