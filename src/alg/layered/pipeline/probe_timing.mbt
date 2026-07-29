// Investigation only, with the `probe_timed` calls in `elk_layered.mbt`.
//
// Not `with_execution_time_measurement` / `get_execution_time`: nothing in
// the repository ever writes a duration into `execution_time`, so it reads
// back 0.0.
//
// Keyed by invocation order, not task name. With no caller-supplied
// monitor, `recursive_graph_layout_engine` substitutes a null one, whose
// `sub_task` returns itself and whose `get_task_name()` is always empty, so
// names would collapse every processor into one bucket. The index is stable
// across runs, so a separate run with a real monitor supplies them.

///|
priv struct ProbeEntry {
  index : Int
  name : String
  elapsed : Double
}

///|
let probe_records : Array[ProbeEntry] = []

///|
/// Call before each measured run, otherwise the previous run is included.
pub fn probe_timing_reset() -> Unit {
  probe_records.clear()
}

///|
/// Wrap one processor invocation and time it. The name is whatever the
/// processor passed to `monitor.begin(...)`, read back after it returns —
/// empty under a null monitor.
pub fn probe_timed(sub : @core.IElkProgressMonitor?, run : () -> Unit) -> Unit {
  let index = probe_records.length()
  let start = @bench.monotonic_clock_start()
  run()
  let elapsed = @bench.monotonic_clock_end(start)
  probe_records.push({
    index,
    name: match sub {
      Some(monitor) => monitor.get_task_name()
      None => ""
    },
    elapsed,
  })
}

///|
/// (invocation index, task name, elapsed) in execution order.
///
/// Summing the elapsed column should land close to an independently
/// measured total for the whole layout call; a large shortfall means
/// processors are running somewhere this instrumentation does not cover.
pub fn probe_timing_dump() -> Array[(Int, String, Double)] {
  probe_records.map(entry => (entry.index, entry.name, entry.elapsed))
}
