from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

# Mock in-memory "database"
users_db = {}

class SignupRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/signup")
def signup(user: SignupRequest):
    if user.email in users_db:
        raise HTTPException(status_code=400, detail="User already exists")
    users_db[user.email] = {
        "name": user.name,
        "password": user.password
    }
    return {"message": "✅ Signup successful", "user": user.name}


@router.post("/login")
def login(user: LoginRequest):
    if user.email not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    if users_db[user.email]["password"] != user.password:
        raise HTTPException(status_code=401, detail="Incorrect password")
    return {"message": "✅ Login successful", "user": users_db[user.email]["name"]}

