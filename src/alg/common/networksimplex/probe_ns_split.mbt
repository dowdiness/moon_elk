// Investigation only.
//
// Iterations are counted separately from the cost of one iteration because
// a single total cannot tell "pivots too often" from "each pivot is too
// slow", and those need different fixes.
//
// `runs` counts calls to `execute`, not layouts. The layerer can solve
// several graphs within one layout, and the per-run averages are only
// meaningful against that count.

///|
pub struct ProbeNsSplit {
  mut runs : Int
  mut iterations : Int
  mut nodes_seen : Int
  mut edges_seen : Int
  mut leave_edge : Double
  mut enter_edge : Double
  mut exchange : Double
  mut initialize : Double
  mut feasible_tree : Double
  mut finalize : Double
  // ns_exchange, split into its five steps
  mut ex_tree_edges : Double
  mut ex_layer_update : Double
  mut ex_reset_visited : Double
  mut ex_postorder : Double
  mut ex_cutvalues : Double
}

///|
let probe_ns_split : ProbeNsSplit = {
  runs: 0,
  iterations: 0,
  nodes_seen: 0,
  edges_seen: 0,
  leave_edge: 0.0,
  enter_edge: 0.0,
  exchange: 0.0,
  initialize: 0.0,
  feasible_tree: 0.0,
  finalize: 0.0,
  ex_tree_edges: 0.0,
  ex_layer_update: 0.0,
  ex_reset_visited: 0.0,
  ex_postorder: 0.0,
  ex_cutvalues: 0.0,
}

///|
pub fn probe_ns_split_reset() -> Unit {
  probe_ns_split.runs = 0
  probe_ns_split.iterations = 0
  probe_ns_split.nodes_seen = 0
  probe_ns_split.edges_seen = 0
  probe_ns_split.leave_edge = 0.0
  probe_ns_split.enter_edge = 0.0
  probe_ns_split.exchange = 0.0
  probe_ns_split.initialize = 0.0
  probe_ns_split.feasible_tree = 0.0
  probe_ns_split.finalize = 0.0
  probe_ns_split.ex_tree_edges = 0.0
  probe_ns_split.ex_layer_update = 0.0
  probe_ns_split.ex_reset_visited = 0.0
  probe_ns_split.ex_postorder = 0.0
  probe_ns_split.ex_cutvalues = 0.0
}

///|
/// (runs, iterations, nodes, edges, leave, enter, exchange, init, feasible,
/// finalize)
pub fn probe_ns_split_dump() -> (
  Int,
  Int,
  Int,
  Int,
  Double,
  Double,
  Double,
  Double,
  Double,
  Double,
) {
  (
    probe_ns_split.runs,
    probe_ns_split.iterations,
    probe_ns_split.nodes_seen,
    probe_ns_split.edges_seen,
    probe_ns_split.leave_edge,
    probe_ns_split.enter_edge,
    probe_ns_split.exchange,
    probe_ns_split.initialize,
    probe_ns_split.feasible_tree,
    probe_ns_split.finalize,
  )
}

///|
fn probe_ns_record_run(nodes : Int, edges : Int) -> Unit {
  probe_ns_split.runs = probe_ns_split.runs + 1
  probe_ns_split.nodes_seen = probe_ns_split.nodes_seen + nodes
  probe_ns_split.edges_seen = probe_ns_split.edges_seen + edges
}

///|
fn probe_ns_record_iteration() -> Unit {
  probe_ns_split.iterations = probe_ns_split.iterations + 1
}

///|
fn probe_ns_add_leave_edge(elapsed : Double) -> Unit {
  probe_ns_split.leave_edge = probe_ns_split.leave_edge + elapsed
}

///|
fn probe_ns_add_enter_edge(elapsed : Double) -> Unit {
  probe_ns_split.enter_edge = probe_ns_split.enter_edge + elapsed
}

///|
fn probe_ns_add_exchange(elapsed : Double) -> Unit {
  probe_ns_split.exchange = probe_ns_split.exchange + elapsed
}

///|
fn probe_ns_add_initialize(elapsed : Double) -> Unit {
  probe_ns_split.initialize = probe_ns_split.initialize + elapsed
}

///|
fn probe_ns_add_feasible_tree(elapsed : Double) -> Unit {
  probe_ns_split.feasible_tree = probe_ns_split.feasible_tree + elapsed
}

///|
fn probe_ns_add_finalize(elapsed : Double) -> Unit {
  probe_ns_split.finalize = probe_ns_split.finalize + elapsed
}

///|
/// (tree edge bookkeeping, layer update, reset visited, postorder, cutvalues)
pub fn probe_ns_exchange_dump() -> (Double, Double, Double, Double, Double) {
  (
    probe_ns_split.ex_tree_edges,
    probe_ns_split.ex_layer_update,
    probe_ns_split.ex_reset_visited,
    probe_ns_split.ex_postorder,
    probe_ns_split.ex_cutvalues,
  )
}

///|
fn probe_ns_add_ex_tree_edges(elapsed : Double) -> Unit {
  probe_ns_split.ex_tree_edges = probe_ns_split.ex_tree_edges + elapsed
}

///|
fn probe_ns_add_ex_layer_update(elapsed : Double) -> Unit {
  probe_ns_split.ex_layer_update = probe_ns_split.ex_layer_update + elapsed
}

///|
fn probe_ns_add_ex_reset_visited(elapsed : Double) -> Unit {
  probe_ns_split.ex_reset_visited = probe_ns_split.ex_reset_visited + elapsed
}

///|
fn probe_ns_add_ex_postorder(elapsed : Double) -> Unit {
  probe_ns_split.ex_postorder = probe_ns_split.ex_postorder + elapsed
}

///|
fn probe_ns_add_ex_cutvalues(elapsed : Double) -> Unit {
  probe_ns_split.ex_cutvalues = probe_ns_split.ex_cutvalues + elapsed
}
