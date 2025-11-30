

def make_solo_graph2(graph_name: str, package_name: str) -> str:
    with open("/Users/sam/Dev/mojo/MMMAudio/mmm_src/MMMAudioBridge.mojo", "r", encoding="utf-8") as src:
        string = src.read()  
        string = string.replace("examples", package_name)
        string = string.replace("FeedbackDelays", graph_name)
        # string = string.replace("MMMAudioBridge", graph_name + "Bridge")
        string = string.replace("PyInit_MMMAudioBridge", "PyInit_" + graph_name + "Bridge")
    with open(graph_name + "Bridge" + ".mojo", "w") as file:
        file.write(string)

