from mmmaudio import *
m_a = MMMAudio(128, graph_name="TestLineExpLine", package_name="examples.tests")
m_a.start_audio() 

old_val = exprand(100, 1000)
def test_line():
    global old_val
    new_val = exprand(100, 1000)
    m_a.send_floats("line_vals", [old_val, new_val, rrand(0.1, 3)])
    old_val = new_val

m_a.send_int("which", 0)
test_line()
m_a.send_int("which", 1)
test_line()
m_a.send_int("which", 2)
test_line()
m_a.send_int("which", 3)
test_line()


m_a.stop_audio()

