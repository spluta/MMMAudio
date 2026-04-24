
def make_solo_graph(graph_name: str, package_name: str) -> str:
    """This is used during compilation to make a solo graph from the MMMAudioBridge.mojo file."""
    from pathlib import Path
    print(f"Making solo graph {graph_name} in package {package_name}")
    target = Path("MMMAudio/mmm_audio/MMMAudioBridge.mojo")
    with target.open("r", encoding="utf-8") as src:
    # with open("../mmm_audio/MMMAudioBridge.mojo", "r", encoding="utf-8") as src:
        string = src.read()  
        string = string.replace("examples", package_name)
        string = string.replace("FeedbackDelays", graph_name)
        string = string.replace("PyInit_MMMAudioBridge", "PyInit_" + graph_name + "Bridge")
        # string = string.replace("MMMAudioBridge", graph_name + "Bridge")
    with open("MMMAudio/" + graph_name + "Bridge" + ".mojo", "w") as file:
        file.write(string)

