def run_moonbeam(plan):
    exec_command = [
        "--chain=dev",
        "--collator",
        "--rpc-external",
        "--rpc-cors=all",
        "--rpc-methods=unsafe",
        "--tmp",
        "--unsafe-rpc-external",
        "--",
        "--wasm-execution=compiled",
        "--chain=/app/rococo-local.json"
    ]
    moonbeam_service_config = ServiceConfig(
        image = "moonbeamfoundation/moonbeam:sha-32933811",
        files = {
            "/app": "configs",
        },
        ports = {
            "ws": PortSpec(9944, transport_protocol = "TCP"),
        },
        cmd = exec_command,
        entrypoint = ["/moonbeam/moonbeam"]
    )
    plan.add_service(name = "acala-node", config = moonbeam_service_config)

def run_moonriver(plan, args):
    exec_command = [
        "--chain=dev",
        "--collator",
        "--rpc-external",
        "--rpc-cors=all",
        "--rpc-methods=unsafe",
        "--tmp",
        "--unsafe-rpc-external",
        "--",
        "--wasm-execution=compiled",
        "--chain=/app/rococo-local.json"
    ]
    plan.add_service(name = "moonriver-node", config = ServiceConfig(
        image = "moonbeamfoundation/moonbeam:sha-519bd694",
        files = {
            "/app": "configs",
        },
        ports = {
            "9944": PortSpec(9944, transport_protocol = "TCP"),
        },
        cmd = exec_command,
        entrypoint = ["/moonbeam/moonbeam"]
    ))