from networkx import is_isomorphic


class EquivalenceClassDoesNotExist(Exception):
    pass


def get_well_graph_from_graph(graph):
    well_nodes = [
        node for node, attributes
        in graph.nodes.items()
        if attributes["type"] in ["fp_well", "piq_well", "miseq_well"]
    ]

    return graph.subgraph(well_nodes)


def get_equivalence_class_by_shape(equivalence_classes, shape):
    for equivalence_class in equivalence_classes:
        if is_isomorphic(equivalence_class[0], shape, node_match=lambda n1, n2: n1["type"] == n2["type"]):
            return equivalence_class 
    raise EquivalenceClassDoesNotExist


def filter_graphs_by_shape(graphs, shape, ):
    return [
        graph for graph in graphs
        if is_isomorphic(graph, shape, node_match=lambda n1, n2: n1["type"] == n2["type"])
    ]
