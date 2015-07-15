include_recipe "docker"

# Pull docker image
docker_image node[:influxdb][:docker_image] do
	tag node[:influxdb][:docker_image_tag]
	action :pull
end

# Create volume directory
directory node[:influxdb][:data_path] do
	recursive true
	action :create
end

directory node[:influxdb][:config_path] do
	recursive true
	action :create
end

# Build the configuration
template "#{node[:influxdb][:config_path]}/config.toml" do
	source "config.toml.erb"
	variables :config => node[:influxdb][:config]
	action :create
	notifies :restart, "service[influxdb]", :delayed
end

# Run the docker container
docker_container "influxdb" do
	action :run
	image "#{node[:influxdb][:docker_image]}:#{node[:influxdb][:docker_image_tag]}"
	container_name node[:influxdb][:docker_container]
	detach true
	expose [ "#{node[:influxdb][:config][:admin][:port]}",
					 "#{node[:influxdb][:config][:http][:port]}",
					 '8090', '8099']
					 # Ports [8090, 8099] only used for clustering purposes and should not be exposed
	port   [ "#{node[:influxdb][:config][:admin][:port]}:#{node[:influxdb][:config][:admin][:port]}",
				   "#{node[:influxdb][:config][:http][:port]}:#{node[:influxdb][:config][:http][:port]}" ]
	volume [ "#{node[:influxdb][:config_path]}/config.toml:#{node[:influxdb][:container_config_path]}/config.toml",
				   "#{node[:influxdb][:data_path]}:#{node[:influxdb][:container_data_path]}"]
end

service "influxdb" do
	action :nothing
end
