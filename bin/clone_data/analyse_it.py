def get_well_graph_from_graph(graph):
    well_nodes = [
        node for node, attributes
        in graph.nodes.items()
        if attributes["type"] in ["fp_well", "piq_well", "miseq_well"]
    ]

    return graph.subgraph(well_nodes)
