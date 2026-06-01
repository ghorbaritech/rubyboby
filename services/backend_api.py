import json
import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import uvicorn

app = FastAPI(title="Ruby Boby SaaS API")

# Enable CORS for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class PersonaSchema(BaseModel):
    id: str
    name: str
    traits: str
    age: str
    gender: str
    colorValue: int
    language: str
    role: str
    faceZoom: float
    faceYOffset: float
    imageBase64: Optional[str] = None

# File-based database path
DB_FILE = os.path.join(os.path.dirname(__file__), "personas_db.json")

def load_db():
    if os.path.exists(DB_FILE):
        try:
            with open(DB_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading database: {e}")
    
    # Default database configuration
    return {
        "users": {"mock_user@example.com": {"email": "mock_user@example.com", "is_premium": True}},
        "personas": {}
    }

def save_db(db_data):
    try:
        with open(DB_FILE, "w", encoding="utf-8") as f:
            json.dump(db_data, f, indent=2)
    except Exception as e:
        print(f"Error saving database: {e}")

@app.post("/auth/register")
async def register_user(email: str):
    db_data = load_db()
    if email in db_data["users"]:
        return {"message": "User already exists", "email": email}
    db_data["users"][email] = {"email": email, "is_premium": False}
    save_db(db_data)
    return {"message": "Registration successful", "email": email}

@app.get("/personas/{email}")
async def get_user_personas(email: str):
    db_data = load_db()
    return db_data["personas"].get(email, [])

@app.post("/personas/{email}")
async def create_persona(email: str, persona: PersonaSchema):
    print(f"RECEIVED PERSONA: {persona.name} (id: {persona.id}) from {email}")
    db_data = load_db()
    
    if email not in db_data["personas"]:
        db_data["personas"][email] = []
        
    # Check if updating an existing persona or adding new
    existing_idx = -1
    for idx, p in enumerate(db_data["personas"][email]):
        if p["id"] == persona.id:
            existing_idx = idx
            break
            
    if existing_idx != -1:
        db_data["personas"][email][existing_idx] = persona.dict()
        print(f"Updated persona: {persona.name}")
    else:
        db_data["personas"][email].append(persona.dict())
        print(f"Created new persona: {persona.name}")
        
    save_db(db_data)
    return {"message": "Persona saved successfully", "persona_id": persona.id}

@app.delete("/personas/{email}/{id}")
async def delete_persona(email: str, id: str):
    print(f"DELETING PERSONA: {id} from {email}")
    db_data = load_db()
    if email not in db_data["personas"]:
        raise HTTPException(status_code=404, detail="No personas found for user")
        
    original_len = len(db_data["personas"][email])
    db_data["personas"][email] = [p for p in db_data["personas"][email] if p["id"] != id]
    
    if len(db_data["personas"][email]) == original_len:
        raise HTTPException(status_code=404, detail="Persona not found")
        
    save_db(db_data)
    return {"message": "Persona deleted successfully"}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
