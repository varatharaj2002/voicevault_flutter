import os
import whisper
import tempfile
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from routes import auth_routes
from dotenv import load_dotenv

# ✅ Load environment variables
load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

if not OPENAI_API_KEY:
    raise RuntimeError("❌ Missing OPENAI_API_KEY in .env file!")

# ✅ Create FastAPI app
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Load Whisper model
print("Loading Whisper model: small (please wait...)")
model = whisper.load_model("small")
print("✅ Whisper model loaded successfully!")

# ✅ Include authentication routes
app.include_router(auth_routes.router, prefix="/auth")

@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".m4a") as tmp:
            tmp.write(await file.read())
            temp_path = tmp.name

        result = model.transcribe(temp_path)
        text = result["text"]

        os.remove(temp_path)
        return {"success": True, "text": text}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ✅ Test route
@app.get("/")
def root():
    return {"message": "🚀 FastAPI backend running successfully"}
