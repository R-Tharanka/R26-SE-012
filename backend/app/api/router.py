from fastapi import APIRouter

from app.api.routes.grading_forecast import router as grading_forecast_router

api_router = APIRouter()
api_router.include_router(grading_forecast_router)

