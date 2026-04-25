import os

def make_solo_graph(dir: str, graph_name: str) -> str:
    """This is used during compilation to make a solo graph from the MMMAudioBridge.mojo file."""
        
    with open("./mmmaudio/src/mmmaudio/MMMAudioBridge.mojo", "r", encoding="utf-8") as src:
        string = src.read()  
        string = string.replace("FeedbackDelays", graph_name)
        string = string.replace("PyInit_MMMAudioBridge", "PyInit_" + graph_name + "Bridge")
    bridge_path = os.path.join(dir, f"{graph_name}Bridge.mojo")
    print(f"Writing solo graph to {bridge_path}")
    with open(bridge_path, "w") as file:
        file.write(string)
    return bridge_path

