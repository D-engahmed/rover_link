from controller import Action, SensorState, decide
from safety import enforce

def test_clear_path_moves_forward():
    assert decide(SensorState(100, 80, 90)) == Action.FORWARD

def test_close_front_turns_to_clearer_side():
    assert decide(SensorState(30, 100, 50)) == Action.LEFT

def test_both_sides_blocked_stops():
    assert decide(SensorState(30, 20, 25)) == Action.STOP

def test_missing_front_stops():
    assert decide(SensorState(None, 100, 100)) == Action.STOP

def test_safety_overrides_forward():
    state = SensorState(25, 100, 100)
    assert enforce(Action.FORWARD, state) == Action.STOP
