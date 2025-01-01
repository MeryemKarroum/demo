from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
from PIL import Image
import io
import tensorflow as tf

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
fruit_model = tf.keras.models.load_model("CNN_fruits.h5")
fashion_model = tf.keras.models.load_model("fashion.h5")  # Updated model name for ANN

# Define class labels
fruit_labels = ["apple", "banana", "orange"]
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

@app.post("/classify/fashion")
async def classify_fashion(file: UploadFile = File(...)):
    # Read and preprocess the image
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))
    
    # Convert to grayscale (if necessary) and then convert to RGB
    image = image.convert("RGB")  # Convert to RGB (3 channels)

    # Resize the image to the expected size for the model
    image = image.resize((32, 32))  # Resize to (32, 32) for the fashion model
    
    # Normalize the image and convert to numpy array
    image_array = np.array(image) / 255.0  # Normalize the image
    
    # Reshape the image to (1, 32, 32, 3) to match the model's input shape
    image_array = np.expand_dims(image_array, axis=0)

    # Make prediction
    predictions = fashion_model.predict(image_array)
    predicted_class = fashion_labels[np.argmax(predictions[0])]
    confidence = float(np.max(predictions[0]))

    return {"type": "fashion", "class": predicted_class, "confidence": confidence}

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
