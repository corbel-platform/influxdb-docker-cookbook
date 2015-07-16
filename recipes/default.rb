include_recipe "docker"

# Pull docker image
docker_image node[:influxdb][:docker_image] do
	tag node[:influxdb][:docker_image_tag]
	action :pull
	notifies :redeploy, 'docker_container[influxdb]', :immediately
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
	variables ({
			:config => node[:influxdb][:config],
			:data_path => node[:influxdb][:container_data_path]
		})
	action :create
	notifies :restart, "docker_container[influxdb]", :delayed
end

# Run the docker container
docker_port = as_list(node[:influxdb][:docker_ports])
docker_container "influxdb" do
	action :run
	image "#{node[:influxdb][:docker_image]}:#{node[:influxdb][:docker_image_tag]}"
	container_name node[:influxdb][:docker_container]
	detach true
	port   docker_port
	volume [ "#{node[:influxdb][:config_path]}/config.toml:#{node[:influxdb][:container_config_path]}/config.toml",
				   "#{node[:influxdb][:data_path]}:#{node[:influxdb][:container_data_path]}"]
end

def as_list(value)
  if value.is_a? String
    value.split(',').map {|s| s.strip}
  else
    value
  end
end
