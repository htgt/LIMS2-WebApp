from unittest import TestCase

from networkx import Graph
from networkx.utils import graphs_equal

from analyse_it import (
    convert_alphanumeric_well_name_to_numeric,
    convert_numeric_well_name_to_alphanumeric,
    filter_graphs_by_shape,
    get_well_graph_from_graph,
    get_equivalence_class_by_shape,
    EquivalenceClassDoesNotExist
)


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


class TestFilterGraphsBySHape(TestCase):
    def test_only_returns_isomorphic_graphs(self):
        graph_shape = Graph()
        graph_shape.add_node("A", type="fp_well")
        graph_shape.add_node("B", type="piq_well")
        graph_shape.add_edges_from([
            ("A", "B"),
        ])
        graph_of_correct_shape = Graph()
        graph_of_correct_shape.add_node("FP1", type="fp_well")
        graph_of_correct_shape.add_node("PIQ2", type="piq_well")
        graph_of_correct_shape.add_edges_from([
            ("FP1", "PIQ2"),
        ])
        graph_missing_node = Graph()
        graph_missing_node.add_node("FP1", type="fp_well")
        graph_with_extra_node = Graph()
        graph_with_extra_node.add_node("FP1", type="fp_well")
        graph_with_extra_node.add_node("PIQ2", type="piq_well")
        graph_with_extra_node.add_node("Miseq3", type="miseq_well")
        graph_with_extra_node.add_edges_from([
            ("FP1", "PIQ2"),
            ("PIQ2", "Miseq3"),
        ])
        input_graphs = [
            graph_of_correct_shape,
            graph_missing_node,
            graph_with_extra_node,
        ]

        output_graphs = filter_graphs_by_shape(input_graphs, graph_shape)

        expected_graphs = [graph_of_correct_shape]
        self.assertCountEqual(output_graphs, expected_graphs)

    def test_takes_in_to_account_node_types(self):
        graph_shape = Graph()
        graph_shape.add_node("A", type="fp_well")
        graph_shape.add_node("B", type="piq_well")
        graph_shape.add_edges_from([
            ("A", "B"),
        ])
        graph_with_wrong_node_types = Graph()
        graph_with_wrong_node_types.add_node("FP1", type="fp_well")
        graph_with_wrong_node_types.add_node("PIQ2", type="miseq_well")
        graph_with_wrong_node_types.add_edges_from([
            ("FP1", "PIQ2"),
        ])
        input_graphs = [graph_with_wrong_node_types]

        output_graphs = filter_graphs_by_shape(input_graphs, graph_shape)

        expected_graphs = []
        self.assertCountEqual(output_graphs, expected_graphs)

    def test_can_filter_for_isomorphism_only_for_some_node_types(self):
        graph_shape = Graph()
        graph_shape.add_node("A", type="fp_well")
        graph_shape.add_node("B", type="piq_well")
        graph_shape.add_node("C", type="miseq_well")
        graph_shape.add_node("D", type="miseq_well")
        graph_shape.add_edges_from([
            ("A", "B"),
            ("B", "C"),
            ("B", "D"),
        ])

        graph_with_isomorphic_fp_and_piq_wells = Graph()
        graph_with_isomorphic_fp_and_piq_wells.add_node("EXP", type="experiment")
        graph_with_isomorphic_fp_and_piq_wells.add_node("FP1", type="fp_well")
        graph_with_isomorphic_fp_and_piq_wells.add_node("PIQ2", type="piq_well")
        graph_with_isomorphic_fp_and_piq_wells.add_node("MISEQ3", type="miseq_well")
        graph_with_isomorphic_fp_and_piq_wells.add_edges_from([
            ("FP1", "EXP"),
            ("FP1", "PIQ2"),
            ("PIQ2", "MISEQ3"),
            ("FP1", "EXP"),
        ])
        input_graphs = [graph_with_isomorphic_fp_and_piq_wells]

        output_graphs = filter_graphs_by_shape(
            input_graphs,
            graph_shape,
            with_respect_to_types=["fp_well", "piq_well"]
        )

        expected_graphs = [graph_with_isomorphic_fp_and_piq_wells]
        self.assertCountEqual(output_graphs, expected_graphs)


class TestConvertNumericWellNameToAlphaNumeric(TestCase):
    def test_correct_coversion(self):
        cases = (
            ("1", "A01"),
            ("8", "H01"),
            ("23", "G03"),
            ("89", "A12"),
            ("96", "H12"),
            ("97", "A13"),
            ("104", "H13"),
            ("156", "D20"),
            ("185", "A24"),
            ("192", "H24"),
            ("193", "I01"),
            ("200", "P01"),
            ("258", "J09"),
            ("281", "I12"),
            ("288", "P12"),
            ("289", "I13"),
            ("296", "P13"),
            ("337", "I19"),
            ("377", "I24"),
            ("384", "P24"),
        )
        
        for numeric, alphanumeric in cases:
            with self.subTest(numeric=numeric, alphanumeric=alphanumeric):
                self.assertEqual(convert_numeric_well_name_to_alphanumeric(numeric), alphanumeric)


class ConvertAlphaNumericWellNameToNumeric(TestCase):
    def test_correct_coversion(self):
        cases = (
            ("A01", "1"),
            ("H01", "8"),
            ("G03", "23"),
            ("A12", "89"),
            ("H12", "96"),
            ("A13", "97"),
            ("H13", "104"),
            ("D20", "156"),
            ("A24", "185"),
            ("H24", "192"),
            ("I01", "193"),
            ("P01", "200"),
            ("J09", "258"),
            ("I12", "281"),
            ("P12", "288"),
            ("I13", "289"),
            ("P13", "296"),
            ("I19", "337"),
            ("I24", "377"),
            ("P24", "384"),
        )

        for alphanumeric, numeric in cases:
            with self.subTest(alphanumeric=alphanumeric, numeric=numeric):
                self.assertEqual(convert_alphanumeric_well_name_to_numeric(alphanumeric), numeric)
