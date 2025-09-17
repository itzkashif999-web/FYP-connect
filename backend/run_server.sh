#!/bin/bash

# Check if the Ollama model is installed
echo "Checking if the Ollama model (3:1b) is installed..."
if ! ollama list | grep -q "3:1b"; then
    echo "Model 3:1b not found. Installing..."
    ollama pull 3:1b
else
    echo "Model 3:1b is already installed."
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
fi

# Start the Flask server
echo "Starting the Flask server..."
python app.py