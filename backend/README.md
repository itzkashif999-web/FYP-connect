# Ollama AI Recommendation Backend

This backend server connects your Flutter app to a local Ollama LLM for AI-powered supervisor recommendations.

## Setup Instructions

1. **Install Required Python Packages**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure Environment**:
   Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file if needed (default settings should work for most cases):
   - `OLLAMA_API_URL`: URL for your local Ollama instance (default: `http://localhost:11434/api/generate`)
   - `OLLAMA_MODEL`: The model to use (default: `3:1b`)
   - `PORT`: Port to run the Flask server on (default: `5000`)

3. **Install Ollama and the 3:1b Model**:
   Make sure Ollama is installed on your system. If not, visit [https://ollama.ai](https://ollama.ai) for installation instructions.
   
   Then pull the 3:1b model:
   ```bash
   ollama pull 3:1b
   ```

4. **Start the Server**:
   ```bash
   ./run_server.sh
   ```
   Or manually with:
   ```bash
   python app.py
   ```

## API Endpoints

- `GET /health`: Check if the server is running
- `POST /recommend`: Get AI recommendations based on student and supervisor profiles

## How It Works

1. The Flask server receives student profile data and supervisor information from your Flutter app.
2. It formats a prompt for Ollama that includes:
   - Student interests and skills
   - Supervisor specializations, preference areas, and project history
3. The prompt asks Ollama to recommend the best supervisor matches
4. Ollama returns recommendations with match explanations
5. The Flask server formats the response and sends it back to your Flutter app

## Troubleshooting

- **Server Won't Start**: Check Python installation and required packages
- **Connection Errors**: Ensure Ollama is running (`ollama serve` command)
- **No Model Found**: Run `ollama pull 3:1b` to download the model
- **CORS Issues**: If testing from a web browser, check CORS settings in the Flask app