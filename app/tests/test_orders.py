"""
Unit tests for the Order API.
Run with: pytest -v
This is exactly what Jenkins will run in the CI stage in Week 3.
"""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_create_order_success():
    payload = {"customer_name": "Anu Datas", "item": "Wireless Mouse", "quantity": 2}
    response = client.post("/orders", json=payload)
    assert response.status_code == 201
    body = response.json()
    assert body["customer_name"] == "Anu Datas"
    assert body["item"] == "Wireless Mouse"
    assert body["quantity"] == 2
    assert body["status"] == "pending"
    assert "order_id" in body


def test_create_order_invalid_quantity():
    payload = {"customer_name": "Anu Datas", "item": "Wireless Mouse", "quantity": 0}
    response = client.post("/orders", json=payload)
    assert response.status_code == 422  # Pydantic validation error


def test_get_order_found():
    create_resp = client.post(
        "/orders",
        json={"customer_name": "Ravi", "item": "Keyboard", "quantity": 1},
    )
    order_id = create_resp.json()["order_id"]

    get_resp = client.get(f"/orders/{order_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["order_id"] == order_id


def test_get_order_not_found():
    response = client.get("/orders/does-not-exist")
    assert response.status_code == 404


def test_list_orders():
    client.post("/orders", json={"customer_name": "Test", "item": "Item", "quantity": 1})
    response = client.get("/orders")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
    assert len(response.json()) >= 1
