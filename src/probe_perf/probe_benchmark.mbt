// Run: moon bench --release -p Milky2018/moon_elk/probe_perf
//
// Not the per-processor probe in `probe.mbt`: it is single-run and its rows
// swing by tens of percent, which is enough to find the dominant processor
// but not to judge whether a change made things faster.
//
// Not diago's own benchmarks either: diago resolves moon_elk from the
// registry, so a local change here is invisible to it.

///|
test "bench/layout/elk_100" (b : @bench.T) {
  ensure_linked()
  let graph = probe_graph_json(100, 3, 0)
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
  ensure_linked()
  let graph = probe_graph_json(200, 3, 0)
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
  ensure_linked()
  let graph = probe_graph_json(200, 3, 400)
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
  ensure_linked()
  let graph = probe_graph_json(200, 3, 0, labelled=true)
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
  ensure_linked()
  let graph = probe_graph_json(200, 3, 400, labelled=true)
  b.bench(() => {
    b.keep(
      @core.new_elk_engine().layout(graph~) catch {
        _ => abort("layout failed")
      },
    )
  })
}
