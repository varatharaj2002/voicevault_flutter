from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

# Temporary in-memory database
users_db = {}

class SignupRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

@app.get("/")
def root():
    return {"message": "FastAPI backend running!"}

@app.post("/signup")
def signup(user: SignupRequest):
    if user.email in users_db:
        raise HTTPException(status_code=400, detail="User already exists")

    users_db[user.email] = {
        "name": user.name,
        "password": user.password
    }
    return {"success": True, "message": f"User {user.name} registered successfully"}

@app.post("/login")
def login(user: LoginRequest):
    if user.email not in users_db:
        raise HTTPException(status_code=401, detail="User not found")
    if users_db[user.email]["password"] != user.password:
        raise HTTPException(status_code=401, detail="Invalid password")

    return {"success": True, "message": f"Welcome back, {users_db[user.email]['name']}!"}
