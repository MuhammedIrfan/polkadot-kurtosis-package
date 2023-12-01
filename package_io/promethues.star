SERVICE_NAME = "prometheus"
PROMETHEUS_DEFAULT_SCRAPE_INTERVAL = "5s"
METRICS_INFO_ADDITIONAL_CONFIG_KEY = "config"
IMAGE_NAME = "prom/prometheus:latest"
HTTP_PORT_ID = "http"
HTTP_PORT_NUMBER = 9090
CONFIG_FILENAME = "prometheus-config.yml"
CONFIG_DIR_MOUNTPOINT_ON_PROMETHEUS = "/config"

shared_utils = import_module("./utils.star")

USED_PORTS = {
    HTTP_PORT_ID: shared_utils.new_port_spec(
        HTTP_PORT_NUMBER,
        "TCP",
        "http",
    ),
}

def launch_prometheus(
        plan,
        args,
        service_details,
        config_template):
    template_data = new_config_template_data(
        plan,
        args,
        service_details,
    )
    template_and_data = shared_utils.new_template_and_data(
        config_template,
        template_data,
    )
    template_and_data_by_rel_dest_filepath = {}
    template_and_data_by_rel_dest_filepath[CONFIG_FILENAME] = template_and_data

    config_files_artifact_name = plan.render_templates(
        template_and_data_by_rel_dest_filepath,
        "prometheus-config",
    )

    config = get_config(config_files_artifact_name)
    prometheus_service = plan.add_service(SERVICE_NAME, config)

    private_ip_address = prometheus_service.ip_address
    prometheus_service_http_port = prometheus_service.ports[HTTP_PORT_ID].number

    return "http://{0}:{1}".format(private_ip_address, prometheus_service_http_port)

def get_config(config_files_artifact_name):
    config_file_path = shared_utils.path_join(
        CONFIG_DIR_MOUNTPOINT_ON_PROMETHEUS,
        shared_utils.path_base(CONFIG_FILENAME),
    )
    return ServiceConfig(
        image = IMAGE_NAME,
        ports = USED_PORTS,
        public_ports = USED_PORTS,
        files = {CONFIG_DIR_MOUNTPOINT_ON_PROMETHEUS: config_files_artifact_name},
        cmd = [
            "--config.file=" + config_file_path,
            "--storage.tsdb.path=/prometheus",
            "--storage.tsdb.retention.time=1d",
            "--storage.tsdb.retention.size=512MB",
            "--storage.tsdb.wal-compression",
            "--web.console.libraries=/etc/prometheus/console_libraries",
            "--web.console.templates=/etc/prometheus/consoles",
            "--web.enable-lifecycle",
        ],
    )

def new_config_template_data(plan, args, service_details):
    metrics_jobs = []

    if len(args["relaychain"]) != 0:
        relay_nodes = args["relaychain"]["nodes"]
        for node in relay_nodes:
            if node["prometheus"] == True:
                for relay_chain in service_details["relaychains"]:
                    node_name = relay_chain["service_details"].name
                    if node_name.endswith(node["name"]):
                        ip = relay_chain["service_details"].ip_address
                        port_number = relay_chain["service_details"].ports["metrics"].number
                        endpoint = "{0}:{1}".format(ip, port_number)
                        metrics_jobs.append(
                            new_metrics_job(
                                job_name = "relay_service_{}".format(node["name"]),
                                endpoint = endpoint,
                                scrape_interval = "5s",
                            ),
                        )
                        
    for parachain in args["para"]:
        for node in parachain["nodes"]:
            if node["prometheus"] == True:
                 for para_chain in service_details["parachains"]:
                    for para_chain_node in para_chain["nodes"]:
                        service_name = para_chain_node["node_details"].name
                        string = "{}-{}-{}".format(parachain["name"],node["name"],args["chain-type"])
                        if string == service_name:
                            ip = para_chain_node["node_details"].ip_address
                            port_number = para_chain_node["node_details"].ports["metrics"].number
                            endpoint = "{0}:{1}".format(ip, port_number)
                            metrics_jobs.append(
                                new_metrics_job(
                                    job_name = "parachain_{}_service_{}".format(parachain["name"],node["name"]),
                                    endpoint = endpoint,
                                    scrape_interval = "5s",
                                ),
                            )

    return {
        "MetricsJobs": metrics_jobs,
    }

def new_metrics_job(
        job_name,
        endpoint,
        scrape_interval = PROMETHEUS_DEFAULT_SCRAPE_INTERVAL):
    return {
        "Name": job_name,
        "Endpoint": endpoint,
        "ScrapeInterval": scrape_interval,
    }
