# Add 100 workers and initialize MPI between them
using MPI

manager = MPIManager(
	np = 100,
	mpirun_cmd = ```
		mpiexec -x JULIA_NUM_THREADS=8 -v
			-mca plm_rsh_no_tree_spawn 1
			-np 100 --map-by node
			--hostfile all_hosts
		```
	)

addprocs(manager)

# Load Celeste
using Celeste

@everywhere ENV["CELESTE_RANKS_PER_NODE"] = 1
@everywhere ENV["CELESTE_THREADS_PER_CORE"] = 1
!isdefined(:CelesteMultiNode) &&
	@everywhere include(joinpath(Pkg.dir("Celeste"), "src", "multinode_run.jl"))
include(Pkg.dir("Celeste", "bin", "binutil.jl"))

# Load Input settings
strategy = Celeste.read_settings_file(joinpath(ENV["HOME"], "iosettings.yml"))
all_rcfs, all_rcf_nsrcs = parse_rcfs_nsrcs(joinpath(ENV["HOME"], "data", "rcf_nsrcs"))
boxes, boxes_rcf_idxs = parse_boxfile(joinpath(ENV["HOME"], "data", "present_boxes"))

# Launch an nginx process for serving large static files
run(pipeline(ignorestatus(`killall nginx`), stderr=DevNull))
spawn(`nginx -p /home/juliaclusteradmin -c simple_nginx.conf`)

# Tell each worker to run Celeste
for worker in workers()
    remote_do(
    	Celeste.ParallelRun.infer_boxes,
    	worker,
    	CelesteMultiNode.DtreeStrategy(),
        all_rcfs,
        all_rcf_nsrcs,
        [boxes],
        [boxes_rcf_idxs],
        Celeste.SDSSIO.HTTPStrategy("10.0.0.14:10400", strategy),
        true,
        joinpath(ENV["HOME"],"output")
    )
end
