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


def filter_graphs_by_shape(graphs, shape, with_respect_to_types=None):
    return [
        graph for graph in graphs
        if is_isomorphic(
            _get_subgraph_with_nodes_of_types(graph, with_respect_to_types) if with_respect_to_types else graph,
            _get_subgraph_with_nodes_of_types(shape, with_respect_to_types) if with_respect_to_types else shape,
            node_match=lambda n1, n2: n1["type"] == n2["type"],
        )
    ]


def _get_subgraph_with_nodes_of_types(graph, types):
    nodes_of_correct_type = [
        node for node, attributes
        in graph.nodes.items()
        if attributes["type"] in types
    ]

    return graph.subgraph(nodes_of_correct_type)
