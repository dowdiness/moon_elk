// Run: moon test -p Milky2018/moon_elk/probe_perf --release
//
// The input mirrors the ELK JSON diago (moonbit-community/diago) emits,
// read off real `debug_build_elk_input_json` output for a 6-node graph.
// Upstream node widths vary between 119 and 120 with label length; fixed at
// 120 here, which does not affect layout cost.
//
// Single runs behind a discarded warm-up, not benchmark means — use
// `probe_benchmark.mbt` to judge a change. Calibration: the per-processor
// total should land near the layout cost measured with `moon bench` in
// diago's `probe_perf`, 45.6 ms at 200 nodes and 93.5 ms at 200 nodes with
// 400 cross edges.

///|
fn probe_node(id : String, label : String) -> Json {
  {
    "id": Json::string(id),
    "x": Json::number(0),
    "y": Json::number(0),
    "width": Json::number(120),
    "height": Json::number(66),
    "labels": Json::array([
      {
        "text": Json::string(label),
        "x": Json::number(0),
        "y": Json::number(0),
        "width": Json::number(74),
        "height": Json::number(21),
      },
    ]),
    "layoutOptions": {
      "elk.direction": Json::string(""),
      "elk.layered.edgeRouting.selfLoopDistribution": Json::string("EQUALLY"),
      "elk.spacing.nodeSelfLoop": Json::number(0),
    },
  }
}

///|
fn probe_edge(id : String, from : String, to : String) -> Json {
  {
    "id": Json::string(id),
    "sources": Json::array([Json::string(from)]),
    "targets": Json::array([Json::string(to)]),
    "container": Json::string(""),
  }
}

///|
/// An edge carrying a label, shaped like the ones in the `issue12` parity
/// corpus, where the c4 and classes diagrams label nearly every edge.
///
/// This matters beyond label placement cost. ELK turns edge labels into
/// dummy nodes, and dummies carry no `model_order`, so labelled edges can
/// disqualify layers from the fast path that a label-free graph would have
/// qualified.
fn probe_edge_labeled(
  id : String,
  from : String,
  to : String,
  text : String,
) -> Json {
  {
    "id": Json::string(id),
    "sources": Json::array([Json::string(from)]),
    "targets": Json::array([Json::string(to)]),
    "container": Json::string(""),
    "labels": Json::array([
      {
        "text": Json::string(text),
        "x": Json::number(0),
        "y": Json::number(0),
        "width": Json::number(74),
        "height": Json::number(21),
        "layoutOptions": {
          "elk.direction": Json::string(""),
          "elk.edgeLabels.inline": Json::boolean(true),
          "elk.spacing.nodeSelfLoop": Json::number(0),
        },
      },
    ]),
  }
}

///|
/// A layered DAG: `fanout` picks each node's parent, then `cross` extra
/// edges jump across layers. Same shape as diago's `probe_graph`.
fn probe_graph_json(
  nodes : Int,
  fanout : Int,
  cross : Int,
  labelled? : Bool = false,
) -> Json {
  let children = Array::makei(nodes, i => probe_node("n\{i}", "xxxxxxxx\{i}"))
  let make_edge = (id, from, to) => {
    if labelled {
      probe_edge_labeled(id, from, to, "uses")
    } else {
      probe_edge(id, from, to)
    }
  }
  let edges = Array::makei(nodes - 1, i => {
    let child = i + 1
    let parent = child / fanout
    make_edge("(n\{parent} -> n\{child})[0]", "n\{parent}", "n\{child}")
  })
  for k in 0..<cross {
    let from = k % (nodes / 2)
    let to = from + nodes / 2
    if to < nodes {
      edges.push(make_edge("(n\{from} -> n\{to})[x\{k}]", "n\{from}", "n\{to}"))
    }
  }
  {
    "id": Json::string(""),
    "layoutOptions": {
      "elk.algorithm": Json::string("layered"),
      "elk.direction": Json::string("DOWN"),
      "elk.hierarchyHandling": Json::string("INCLUDE_CHILDREN"),
      "elk.layered.nodePlacement.bk.fixedAlignment": Json::string("BALANCED"),
      "elk.layered.considerModelOrder.strategy": Json::string("NODES_AND_EDGES"),
      "elk.layered.cycleBreaking.strategy": Json::string("GREEDY_MODEL_ORDER"),
      "elk.layered.thoroughness": Json::number(8),
      "elk.layered.spacing.edgeEdgeBetweenLayers": Json::number(50),
      "elk.spacing.edgeNode": Json::number(40),
      "elk.nodeSize.constraints": Json::string("MINIMUM_SIZE"),
      "elk.contentAlignment": Json::string("H_CENTER V_CENTER"),
      "spacing.nodeNodeBetweenLayers": Json::number(70),
      "spacing.edgeNodeBetweenLayers": Json::number(40),
      "elk.spacing.nodeSelfLoop": Json::number(50),
    },
    "children": Json::array(children),
    "edges": Json::array(edges),
  }
}

///|
/// Make sure the JSON adapter and the layered pipeline are linked in.
/// Same role as diago's `ensure_moon_elk_json_bootstrap_linked`.
fn ensure_linked() -> Unit {
  ignore(@elk_json.new_json_adapter)
  ignore(@pipeline.layered_pipeline_linked)
  ignore(@layered_engine.layered_engine_linked)
}

///|
/// Processor names by invocation index. Under the null monitor every
/// `get_task_name()` is empty, so names cannot be read in the run that
/// produces trustworthy timings; these were captured separately with
/// `core_elk_engine_delegate.mbt` handing the recursive engine a real
/// `new_elk_progress_monitor()`. The order is deterministic, so the two
/// runs join on the index.
let processor_names : Array[String] = [
  "Graph transformation (TO_INPUT_DIRECTION)", "Edge and layer constraint edge reversal",
  "Greedy cycle removal", "Layer constraint preprocessing", "Network simplex layering",
  "Layer constraint postprocessing", "Edge splitting", "Port side processing", "Port order processing",
  "Sort By Input Model NODES_AND_EDGES", "Minimize Crossings BARYCENTER", "Layer constraint edge reversal",
  "Node and Port Label Placement and Node Sizing", "Node margin calculation", "Brandes & Koepf node placement",
  "Layer size calculation", "Orthogonal edge routing", "Edge joining", "Sort end labels",
  "Restoring reversed edges", "Resize child graph to fit parent.", "Graph transformation (TO_INTERNAL_LTR)",
]

///|
/// Edge labels add four processors — dummy insertion, switching, side
/// selection, removal — and shift every index from the insertion point on.
/// Reading the label-free table against a labelled run silently mislabels
/// the dominant processor, so the table is picked by invocation count.
let processor_names_labelled : Array[String] = [
  "Graph transformation (TO_INPUT_DIRECTION)", "Edge and layer constraint edge reversal",
  "Greedy cycle removal", "Label dummy insertions", "Layer constraint preprocessing",
  "Network simplex layering", "Layer constraint postprocessing", "Edge splitting",
  "Port side processing", "Port order processing", "Sort By Input Model NODES_AND_EDGES",
  "Minimize Crossings BARYCENTER", "Layer constraint edge reversal", "Node and Port Label Placement and Node Sizing",
  "Node margin calculation", "Label dummy switching", "Label side selection (SMART_UP)",
  "Brandes & Koepf node placement", "Layer size calculation", "Orthogonal edge routing",
  "Edge joining", "Label dummy removal", "Sort end labels", "Restoring reversed edges",
  "Resize child graph to fit parent.", "Graph transformation (TO_INTERNAL_LTR)",
]

///|
fn processor_name(index : Int, invocations : Int) -> String {
  let table = if invocations == processor_names_labelled.length() {
    processor_names_labelled
  } else {
    processor_names
  }
  if index < table.length() {
    table[index]
  } else {
    "<unknown #\{index} of \{invocations}>"
  }
}

///|
fn run_and_report(label : String, graph : Json) -> Unit {
  ensure_linked()
  // Warm-up pass, discarded. Without it the first size measured in the
  // process carries start-up cost and reads high — enough to make a
  // processor look like it got *faster* on the larger graph.
  let _ = @core.new_elk_engine().layout(graph~) catch { _ => return }
  @pipeline.probe_timing_reset()
  @runtime.probe_sort_split_reset()
  @networksimplex.probe_ns_split_reset()
  let result = @core.new_elk_engine().layout(graph~) catch {
    e => {
      println("\{label}: layout failed: \{e}")
      return
    }
  }
  // Positive control. If layout really ran, some node ends up with a
  // non-zero y. Without this check, a broken instrument reporting a total
  // of 0 is indistinguishable from "it was fast".
  guard result is Object(root) else {
    println("\{label}: output is not an object — layout did not run")
    return
  }
  guard root.get("children") is Some(Array(children)) else {
    println("\{label}: no children in output — layout did not run")
    return
  }
  let placed = children.any(child => {
    match child {
      Object(node) =>
        match node.get("y") {
          Some(Number(y, ..)) => y != 0.0
          _ => false
        }
      _ => false
    }
  })
  if !placed {
    println("\{label}: every node still at y=0 — layout placed nothing")
    return
  }
  let rows = @pipeline.probe_timing_dump()
  let total = rows.fold(init=0.0, (acc, row) => acc + row.2)
  println(
    "=== \{label} — total \{total} over \{rows.length()} invocations ===",
  )
  for row in rows {
    let share = if total > 0.0 { row.2 / total * 100.0 } else { 0.0 }
    println(
      "#\{row.0}\t\{row.2}\t\{share}%\t\{if row.1.is_empty() { processor_name(row.0, rows.length()) } else { row.1 }}",
    )
  }
  // Inside #9: the per-node port work versus the per-layer node sort, and
  // how many layers could legally skip the comparator.
  let (port_phase, node_sort, layers, qualifying, largest) = @runtime.probe_sort_split_dump()
  let inside = port_phase + node_sort
  let port_share = if inside > 0.0 { port_phase / inside * 100.0 } else { 0.0 }
  let sort_share = if inside > 0.0 { node_sort / inside * 100.0 } else { 0.0 }
  println(
    "  #9 split: port phase \{port_phase} (\{port_share}%), node sort \{node_sort} (\{sort_share}%)",
  )
  println(
    "  #9 layers: \{qualifying}/\{layers} qualify for the model_order fast path, largest layer \{largest}",
  )
  // Inside #4: pivot iterations versus the cost of one iteration.
  let (
    runs,
    iterations,
    ns_nodes,
    ns_edges,
    leave,
    enter,
    exchange,
    init,
    feasible,
    fin,
  ) = @networksimplex.probe_ns_split_dump()
  let loop_total = leave + enter + exchange
  let ns_total = loop_total + init + feasible + fin
  println(
    "  #4 runs \{runs}, solver nodes \{ns_nodes}, solver edges \{ns_edges}",
  )
  println(
    "  #4 iterations \{iterations}, total \{ns_total}, loop \{loop_total}",
  )
  if iterations > 0 {
    println("  #4 per iteration: \{loop_total / iterations.to_double()}")
  }
  println("  #4 leave_edge \{leave}, enter_edge \{enter}, exchange \{exchange}")
  println(
    "  #4 outside loop: initialize \{init}, feasible_tree \{feasible}, finalize \{fin}",
  )
  let (ex_tree, ex_layer, ex_reset, ex_post, ex_cut) = @networksimplex.probe_ns_exchange_dump()
  let ex_sum = ex_tree + ex_layer + ex_reset + ex_post + ex_cut
  println(
    "  #4 exchange split (sum \{ex_sum}): tree_edges \{ex_tree}, layer_update \{ex_layer}, reset_visited \{ex_reset}, postorder \{ex_post}, cutvalues \{ex_cut}",
  )
  if iterations > 0 {
    let n = iterations.to_double()
    println(
      "  #4 exchange per iteration: tree_edges \{ex_tree / n}, layer_update \{ex_layer / n}, reset_visited \{ex_reset / n}, postorder \{ex_post / n}, cutvalues \{ex_cut / n}",
    )
  }
  println("")
}

///|
test "probe layered phase attribution" {
  run_and_report("100 nodes", probe_graph_json(100, 3, 0))
  run_and_report("200 nodes", probe_graph_json(200, 3, 0))
  run_and_report("200 nodes + 400 cross edges", probe_graph_json(200, 3, 400))
  // Same shapes with every edge labelled, as the real corpus does.
  run_and_report(
    "100 nodes, labelled",
    probe_graph_json(100, 3, 0, labelled=true),
  )
  run_and_report(
    "200 nodes, labelled",
    probe_graph_json(200, 3, 0, labelled=true),
  )
  run_and_report(
    "200 nodes + 400 cross edges, labelled",
    probe_graph_json(200, 3, 400, labelled=true),
  )
}
