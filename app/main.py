"""
ShopLite Order API
-------------------
A minimal order-processing service. This is intentionally simple —
the point of this project is the platform around it (CI/CD, IaC,
Kubernetes, observability), not a complex app.
"""

from datetime import datetime, timezone
from enum import Enum
from typing import Dict
from uuid import uuid4

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(
    title="ShopLite Order API",
    description="Order processing service for the ShopLite platform",
    version="1.0.0",
)

# In-memory "database" for now — deliberately simple.
# Swapping this for a real DB (Postgres/DynamoDB) is a natural
# Week 9+ extension once the platform itself is working.
ORDERS: Dict[str, dict] = {}


class OrderStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    SHIPPED = "shipped"
    CANCELLED = "cancelled"


class OrderCreateRequest(BaseModel):
    customer_name: str = Field(..., min_length=1, examples=["Anu Datas"])
    item: str = Field(..., min_length=1, examples=["Wireless Mouse"])
    quantity: int = Field(..., gt=0, examples=[2])


class OrderResponse(BaseModel):
    order_id: str
    customer_name: str
    item: str
    quantity: int
    status: OrderStatus
    created_at: str


@app.get("/health", tags=["ops"])
def health_check():
    """Liveness/readiness probe target for Kubernetes."""
    return {"status": "ok"}


@app.post("/orders", response_model=OrderResponse, status_code=201, tags=["orders"])
def create_order(order: OrderCreateRequest):
    order_id = str(uuid4())
    record = {
        "order_id": order_id,
        "customer_name": order.customer_name,
        "item": order.item,
        "quantity": order.quantity,
        "status": OrderStatus.PENDING,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    ORDERS[order_id] = record
    return record


@app.get("/orders/{order_id}", response_model=OrderResponse, tags=["orders"])
def get_order(order_id: str):
    record = ORDERS.get(order_id)
    if not record:
        raise HTTPException(status_code=404, detail="Order not found")
    return record


@app.get("/orders", tags=["orders"])
def list_orders():
    return list(ORDERS.values())
