from unittest import TestCase

from networkx import Graph
from networkx.utils import graphs_equal

from analyse_it import get_well_graph_from_graph, get_equivalence_class_by_shape, EquivalenceClassDoesNotExist


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


class TestGetEquivalenceClassByShape(TestCase):
    def setUp(self):
        self.one_fp_one_piq_graph = Graph()
        self.one_fp_one_piq_graph.add_node("FP1", type="fp_well")
        self.one_fp_one_piq_graph.add_node("PIQ2", type="piq_well")
        self.one_fp_one_piq_graph.add_edge("FP1", "PIQ2")

        self.one_fp_one_piq_one_miseq_graph = Graph()
        self.one_fp_one_piq_one_miseq_graph.add_node("FP1", type="fp_well")
        self.one_fp_one_piq_one_miseq_graph.add_node("PIQ2", type="piq_well")
        self.one_fp_one_piq_one_miseq_graph.add_node("Miseq3", type="miseq_well")
        self.one_fp_one_piq_one_miseq_graph.add_edges_from([
            ("FP1", "PIQ2"),
            ("PIQ2", "Miseq3"),
        ])


    def test_returns_correct_equivalence_class_when_it_exists(self):
        expected_graph = self.one_fp_one_piq_graph
        another_graph = self.one_fp_one_piq_one_miseq_graph
        equivalence_classes = [
            [expected_graph],
            [another_graph],
        ]
        input_graph = Graph()
        input_graph.add_node("A", type="fp_well")
        input_graph.add_node("B", type="piq_well")
        input_graph.add_edge("A", "B")

        returned_equivalence_class = get_equivalence_class_by_shape(equivalence_classes, input_graph)
        
        self.assertEqual(returned_equivalence_class, [expected_graph])

    def test_raises_when_equivalence_class_of_correct_shape_does_not_exist(self):
        expected_graph = self.one_fp_one_piq_graph
        another_graph = self.one_fp_one_piq_one_miseq_graph
        equivalence_classes = [
            [expected_graph],
            [another_graph],
        ]
        input_graph = Graph()
        input_graph.add_node("A", type="fp_well")
        input_graph.add_node("B", type="piq_well")
        input_graph.add_node("C", type="piq_well")
        input_graph.add_edge("A", "B")
        input_graph.add_edge("A", "C")

        with self.assertRaises(EquivalenceClassDoesNotExist):
            get_equivalence_class_by_shape(equivalence_classes, input_graph)

    def test_takes_in_to_account_type_of_nodes(self):
        expected_graph = self.one_fp_one_piq_graph
        another_graph = self.one_fp_one_piq_one_miseq_graph
        equivalence_classes = [
            [expected_graph],
            [another_graph],
        ]
        input_graph = Graph()
        input_graph.add_node("A", type="fp_well")
        input_graph.add_node("B", type="miseq_well")
        input_graph.add_edge("A", "B")

        with self.assertRaises(EquivalenceClassDoesNotExist):
            get_equivalence_class_by_shape(equivalence_classes, input_graph)
