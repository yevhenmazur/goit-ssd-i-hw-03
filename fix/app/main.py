from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import os
from passlib.context import CryptContext

app = FastAPI()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserResponse(BaseModel):
    id: int
    name: str

class LoginRequest(BaseModel):
    password: str = Field(min_length=8, max_length=128)

class LoginResponse(BaseModel):
    status: str

@app.get("/user", response_model=UserResponse)
def get_user(id: int):
    return {"id": id, "name": "Alice"}

@app.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest):
    # Парольний хеш має надходити з керованого секрету/БД, не з коду
    stored_hash = os.environ.get("USER_API_PASSWORD_HASH")
    if not stored_hash:
        raise HTTPException(status_code=500, detail="Auth not configured")

    if pwd_context.verify(payload.password, stored_hash):
        return {"status": "ok"}

    raise HTTPException(status_code=401, detail="Invalid credentials")
