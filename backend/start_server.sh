#!/bin/bash

echo "Installing dependencies..."
pip install -r requirements.txt

echo "Starting the Ollama API bridge server..."
python app.py