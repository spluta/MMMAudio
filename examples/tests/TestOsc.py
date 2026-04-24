from srcpy import *

# instantiate and load the graph
m_s = []


for i in range(7):
    src_mojo = MMMAudio(128, graph_name="TestOsc", package_name="examples.tests")
    src_mojo.start_audio() 
    m_s.append(src_mojo)

for i in range(7):
    m_s[i].stop_audio()  