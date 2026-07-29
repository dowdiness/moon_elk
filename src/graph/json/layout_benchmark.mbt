// Benchmarks for the layered layout, driven through the public JSON entry
// point so the numbers correspond to what a caller actually pays.
//
// Run: moon bench --release -p Milky2018/moon_elk/graph/json
//
// The graph shapes mirror the ELK JSON that diago
// (moonbit-community/diago) emits, read off its real output for a 6-node
// graph, so root layoutOptions, node sizes, label sizes and edge shape all
// match a real caller rather than a synthetic worst case. Upstream node
// widths vary between 119 and 120 with label length; fixed at 120 here,
// which does not affect layout cost.

///|
fn bench_node(id : String, label : String) -> Json {
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
fn bench_edge(id : String, from : String, to : String) -> Json {
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
fn bench_edge_labeled(
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
fn bench_graph_json(
  nodes : Int,
  fanout : Int,
  cross : Int,
  labelled? : Bool = false,
) -> Json {
  let children = Array::makei(nodes, i => bench_node("n\{i}", "xxxxxxxx\{i}"))
  let make_edge = (id, from, to) => {
    if labelled {
      bench_edge_labeled(id, from, to, "uses")
    } else {
      bench_edge(id, from, to)
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
fn bench_ensure_linked() -> Unit {
  ignore(new_json_adapter)
  ignore(@pipeline.layered_pipeline_linked)
  ignore(@engine.layered_engine_linked)
}

///|
test "bench/layout/elk_100" (b : @bench.T) {
  bench_ensure_linked()
  let graph = bench_graph_json(100, 3, 0)
  b.bench(() => {
    b.keep(
      @core.new_elk_engine().layout(graph~) catch {
        _ => abort("layout failed")
      },
    )
  })
}

///|
test "bench/layout/elk_200" (b : @bench.T) {
  bench_ensure_linked()
  let graph = bench_graph_json(200, 3, 0)
  b.bench(() => {
    b.keep(
      @core.new_elk_engine().layout(graph~) catch {
        _ => abort("layout failed")
      },
    )
  })
}

///|
test "bench/layout/elk_200_cross400" (b : @bench.T) {
  bench_ensure_linked()
  let graph = bench_graph_json(200, 3, 400)
  b.bench(() => {
    b.keep(
      @core.new_elk_engine().layout(graph~) catch {
        _ => abort("layout failed")
      },
    )
  })
}

// Edge labels become dummy nodes carrying no `model_order`, so their
// layers cannot take the fast path and every comparison goes through the
// comparator. The unlabelled cases above are the control.

///|
test "bench/layout/elk_200_labelled" (b : @bench.T) {
  bench_ensure_linked()
  let graph = bench_graph_json(200, 3, 0, labelled=true)
  b.bench(() => {
    b.keep(
      @core.new_elk_engine().layout(graph~) catch {
        _ => abort("layout failed")
      },
    )
  })
}

///|
test "bench/layout/elk_200_cross400_labelled" (b : @bench.T) {
  bench_ensure_linked()
  let graph = bench_graph_json(200, 3, 400, labelled=true)
  b.bench(() => {
    b.keep(
      @core.new_elk_engine().layout(graph~) catch {
        _ => abort("layout failed")
      },
    )
  })
}
