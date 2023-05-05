from unittest import TestCase

from networkx import Graph
from networkx.utils import graphs_equal

from analyse_it import get_well_graph_from_graph


class TestGetWellsSubgraph(TestCase):
    def test_includes_all_and_only_well_nodes_and_their_induced_edges(self):
        input_graph = Graph()
        input_graph.add_node("FP1", type="fp_well")
        input_graph.add_node("PIQ2", type="piq_well")
        input_graph.add_node("Miseq3", type="miseq_well")
        input_graph.add_node("MiseqWellExp4", type="miseq_well_experiment")
        input_graph.add_edges_from([
            ("FP1", "PIQ2"),
            ("PIQ2", "Miseq3"),
            ("Miseq3", "MiseqWellExp4"),
        ])

        output_graph = get_well_graph_from_graph(input_graph)

        expected_graph = Graph()
        expected_graph.add_node("FP1", type="fp_well")
        expected_graph.add_node("PIQ2", type="piq_well")
        expected_graph.add_node("Miseq3", type="miseq_well")
        expected_graph.add_edges_from([
            ("FP1", "PIQ2"),
            ("PIQ2", "Miseq3"),
        ])

        self.assertTrue(graphs_equal(output_graph, expected_graph))
