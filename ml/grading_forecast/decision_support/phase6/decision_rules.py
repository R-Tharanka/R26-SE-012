# =============================================================================
# File: decision rules
# Purpose: Defines the fixed price-direction and outlook decision rules.
# =============================================================================
"""Predeclared deterministic direction, signal, and category rules."""

from __future__ import annotations


def forecast_direction(reference_price: float, forecast_price: float) -> str:
    # Classify the forecast as up, down, or flat.
    reference = round(float(reference_price), 2)
    forecast = round(float(forecast_price), 2)
    return "UP" if forecast > reference else "DOWN" if forecast < reference else "FLAT"


def interval_crosses_reference(reference_price: float, lower: float | None, upper: float | None) -> bool:
    # Check whether the forecast interval crosses the reference price.
    if lower is None or upper is None:
        return False
    return float(lower) < float(reference_price) < float(upper)


def signal_classification(
    reference_price: float,
    interval_lower: float | None,
    interval_upper: float | None,
    model_vs_persistence: str,
) -> str:
    # Classify forecast certainty from its interval and baseline comparison.
    if interval_crosses_reference(reference_price, interval_lower, interval_upper):
        return "HIGH_UNCERTAINTY"
    if model_vs_persistence == "RIDGE_BETTER":
        return "RELATIVE_SUPPORT"
    return "LIMITED_SIGNAL"


def outlook_category(direction: str, signal: str) -> str:
    # Map forecast direction and certainty to the final outlook category.
    if signal == "HIGH_UNCERTAINTY":
        return "HIGH_UNCERTAINTY_OUTLOOK"
    return {"UP": "UPWARD_PRICE_OUTLOOK", "DOWN": "DOWNWARD_PRICE_OUTLOOK", "FLAT": "FLAT_PRICE_OUTLOOK"}[direction]
