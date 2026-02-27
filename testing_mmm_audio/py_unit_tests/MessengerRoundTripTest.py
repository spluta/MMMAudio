import time

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from mmm_python import *

def main():
    m = MMMAudio(128, graph_name="MessengerRoundTripTest", package_name="testing_mmm_audio.py_unit_tests")
    
    # received values
    rv = {}

    m.register_callback("float_return", lambda args: rv.update({"float": args}))
    m.register_callback("floats_return", lambda args: rv.update({"floats": args}))
    m.register_callback("int_return", lambda args: rv.update({"int": args}))
    m.register_callback("ints_return", lambda args: rv.update({"ints": args}))
    m.register_callback("bool_return", lambda args: rv.update({"bool": args}))
    m.register_callback("str_return", lambda args: rv.update({"str": args}))
    m.register_callback("strs_return", lambda args: rv.update({"strs": args}))
    m.register_callback("trig_return", lambda args: rv.update({"trig": args}))
    
    m.register_callback("stream_float", lambda args: rv.update({"stream_float": args}))
    m.register_callback("stream_floats", lambda args: rv.update({"stream_floats": args}))
    m.register_callback("stream_int", lambda args: rv.update({"stream_int": args}))
    m.register_callback("stream_ints", lambda args: rv.update({"stream_ints": args}))
    m.register_callback("stream_bool", lambda args: rv.update({"stream_bool": args}))
    m.register_callback("stream_str", lambda args: rv.update({"stream_str": args}))
    m.register_callback("stream_strs", lambda args: rv.update({"stream_strs": args}))

    m.start_audio()

    # print("callbacks",m.callbacks)

    m.send_float("float",2.1415)
    m.send_floats("floats",[1.0,2.0,3.0])
    m.send_int("int",42)
    m.send_ints("ints",[100, 200, 300])
    m.send_bool("bool",True)
    m.send_string("str","hello")
    m.send_strings("strs",["foo", "bar", "baz"])
    m.send_trig("trig")

    time.sleep(0.1)  

    # expected values
    ev = {
        "float": 3.1415,
        "floats": np.array([2.0, 3.0, 4.0]),
        "int": 43,
        "ints": np.array([101, 201, 301]),
        "bool": False,
        "str": "hello_return",
        "strs": ["foo_return", "bar_return", "baz_return"],
        "trig": None,
        "stream_float": 42.42,
        "stream_floats": np.array([1.1, 2.2, 3.3]),
        "stream_int": 1825,
        "stream_ints": np.array([1776,2026]),
        "stream_bool": True,
        "stream_str": "kenobi",
        "stream_strs": ["luke", "leia", "han"]
    }

    assert rv["float"] == ev["float"], f"Expected {ev}, but got {rv}"
    assert np.array_equal(rv["floats"], ev["floats"]), f"Expected {ev}, but got {rv}"
    assert rv["int"] == ev["int"], f"Expected {ev}, but got {rv}"
    assert np.array_equal(rv["ints"], ev["ints"]), f"Expected {ev}, but got {rv}"
    assert rv["bool"] == ev["bool"], f"Expected {ev}, but got {rv}"
    assert rv["str"] == ev["str"], f"Expected {ev}, but got {rv}"
    assert rv["strs"] == ev["strs"], f"Expected {ev}, but got {rv}"
    assert rv["trig"] == ev["trig"], f"Expected {ev}, but got {rv}"
    assert rv["stream_float"] == ev["stream_float"], f"Expected {ev}, but got {rv}"
    assert np.array_equal(rv["stream_floats"], ev["stream_floats"]), f"Expected {ev}, but got {rv}"
    assert rv["stream_int"] == ev["stream_int"], f"Expected {ev}, but got {rv}"
    assert np.array_equal(rv["stream_ints"], ev["stream_ints"]), f"Expected {ev}, but got {rv}"
    assert rv["stream_bool"] == ev["stream_bool"], f"Expected {ev}, but got {rv}"
    assert rv["stream_str"] == ev["stream_str"], f"Expected {ev}, but got {rv}"
    assert rv["stream_strs"] == ev["stream_strs"], f"Expected {ev}, but got {rv}"
    
    print("MessengerRoundTripTest passed")

    m.stop_audio()
    m.stop_process()

if __name__ == "__main__":
    main()