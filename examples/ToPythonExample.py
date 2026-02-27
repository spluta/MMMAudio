from mmm_python import *
m = MMMAudio(128, graph_name="ToPythonExample", package_name="examples")
m.register_callback("pitch", lambda args: print(f"pitch: {args}"))
m.register_callback("vals", lambda args: print(f"vals: {args}"))
m.register_callback("bool", lambda args: print(f"bool: {args}"))
m.register_callback("trig", lambda args: print(f"trig: {args}"))
m.start_audio()

m.stop_audio()