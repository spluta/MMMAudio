
def make_solo_graph(graph_name: str, package_name: str) -> str:
    """This is used during compilation to make a solo graph from the MMMAudioBridge.mojo file."""
    with open("./mmm_audio/MMMAudioBridge.mojo", "r", encoding="utf-8") as src:
        string = src.read()  
        string = string.replace("examples", package_name)
        string = string.replace("Grains", graph_name)

    with open(graph_name + "Bridge" + ".mojo", "w") as file:
        file.write(string)

