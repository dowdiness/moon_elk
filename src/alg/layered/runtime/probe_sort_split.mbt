// Investigation only.
//
// The layer counters count qualifying layers, not layers. A layer can only
// take the `model_order` fast path if every node carries one and the values
// are distinct within the layer, and edge splitting runs before this
// processor: one of its dummy nodes carries none and disqualifies the whole
// layer.

///|
pub struct ProbeSortSplit {
  mut port_phase : Double
  mut node_sort : Double
  mut layers : Int
  mut layers_qualifying : Int
  mut largest_layer : Int
}

///|
let probe_sort_split : ProbeSortSplit = {
  port_phase: 0.0,
  node_sort: 0.0,
  layers: 0,
  layers_qualifying: 0,
  largest_layer: 0,
}

///|
pub fn probe_sort_split_reset() -> Unit {
  probe_sort_split.port_phase = 0.0
  probe_sort_split.node_sort = 0.0
  probe_sort_split.layers = 0
  probe_sort_split.layers_qualifying = 0
  probe_sort_split.largest_layer = 0
}

///|
/// (port phase, node sort, layers, qualifying layers, largest layer)
pub fn probe_sort_split_dump() -> (Double, Double, Int, Int, Int) {
  (
    probe_sort_split.port_phase,
    probe_sort_split.node_sort,
    probe_sort_split.layers,
    probe_sort_split.layers_qualifying,
    probe_sort_split.largest_layer,
  )
}

///|
pub fn probe_sort_split_add_port_phase(elapsed : Double) -> Unit {
  probe_sort_split.port_phase = probe_sort_split.port_phase + elapsed
}

///|
pub fn probe_sort_split_add_node_sort(elapsed : Double) -> Unit {
  probe_sort_split.node_sort = probe_sort_split.node_sort + elapsed
}

///|
/// Record one layer: does every node carry a distinct `model_order`?
pub fn probe_sort_split_record_layer(nodes : Array[LNode]) -> Unit {
  probe_sort_split.layers = probe_sort_split.layers + 1
  if nodes.length() > probe_sort_split.largest_layer {
    probe_sort_split.largest_layer = nodes.length()
  }
  let seen : @hashset.HashSet[Int] = @hashset.HashSet([])
  let mut qualifies = true
  for node in nodes {
    if !node.has_property_int(internal_properties_model_order) {
      qualifies = false
      break
    }
    let order = node.get_property_int(internal_properties_model_order)
    if seen.contains(order) {
      qualifies = false
      break
    }
    seen.add(order)
  }
  if qualifies {
    probe_sort_split.layers_qualifying = probe_sort_split.layers_qualifying + 1
  }
}
