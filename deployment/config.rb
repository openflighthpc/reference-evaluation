# frozen_string_literal: true

# require_relative "config/version"
require "tty-prompt"
prompt = TTY::Prompt.new

module Config
  class Error < StandardError; end
  prompt = TTY::Prompt.new
  cluster_type = "0"
  num_of_compute_nodes = 0
  compute_instance_size = "0"
  compute_volume_size = "0"
  cram_testing = false
  basic_testing = false
  delete_on_success = false
  sharepubkey = false

  openstack_rc_filepath = "setup/Ivan_testing-openrc.sh"

  stack_name = prompt.ask("Name of cluster?", required: true)  { |q| q.validate(/^[a-z][-a-z0-9]{1,61}[a-z0-9]$/)} # pattern satifies azure and aws requirements

  standalone = prompt.no?("Standalone cluster?") { |q| q.convert } # .convert maybe?
  standalone = !standalone

  platform_choices = %w(openstack aws azure)
  platform = prompt.select("Launch on what platform?", platform_choices)

  size_choices = %w(small medium large GPU)

  login_size = prompt.select("What instance size login node?", size_choices)
  login_volume_size = prompt.ask("What volume size login node? (GB)", default: "20") { |q| q.validate(/^[1-9][0-9]+/)} # accepts >10 GB
  
  unless standalone # if it isn't standalone then
    num_of_compute_nodes = prompt.ask("How many compute nodes?", default: "2") { |q| q.validate(/^10$|^[1-9]$/)} # accept only numbers from 1 to 10
    compute_size = prompt.select("What instance size compute nodes?", size_choices)
    compute_volume_size = prompt.ask("What volume size compute nodes? (GB)", default: "20") { |q| q.validate(/^[1-9][0-9]+/)} # accepts >10 GB
    cluster_type_choices = %w(slurm kubernetes) # cluster type can only be one of these 
  else
    cluster_type_choices = %w(slurm jupyter)# if standalone, cluster type can only be one of these 
  end

  # user data setup section
  advuserdata = prompt.no?("Configure User Data?") { |q| q.convert } 
  advuserdata = !advuserdata 
 
  if advuserdata
    unless standalone
      broadcast = prompt.ask("Compute nodes broadcast? enter address or leave blank for no", default: "") { |q| q.validate(/(^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$)|($^)/)} # regexp to only accept ip address or blank - improvement: make the last "word" 255
    
      if broadcast == ""
        sharepubkey = prompt.no?("Share Public Key?") { |q| q.convert } 
        sharepubkey = !sharepubkey
      end
    end

    #labels and prefixes
    login_label = ""
    login_prefix = ""
    login_name_choices = %w(no label prefix)
    login_name = prompt.select("Should login have a label/prefix?", login_name_choices)
    case login_name
    when "label"
      login_label = prompt.ask("Login label:").delete_prefix('"').delete_suffix('"')
    when "prefix"
      login_prefix = prompt.ask("Login prefix:").delete_prefix('"').delete_suffix('"')
    end
    unless standalone
      cnode_prefix = prompt.ask("Enter prefix for compute nodes: (leave blank for no prefix)", default: "").delete_prefix('"').delete_suffix('"')
    end
    prefix_starts = prompt.ask("Enter prefix start numbers in the form \"node: '01', gpu: '1'\": (leave blank for none)", default: "").delete_prefix('"').delete_suffix('"')

    autoparsematch = prompt.ask("Auto-Parse regex: (leave blank for nothing)", default: "")
    autoapplyrules = prompt.ask("Enter auto-apply rules in the form \"node: compute, controller: login\": (leave blank for none)", default: "").delete_prefix('"').delete_suffix('"')
    

    auto_config_bool = prompt.no?("Automatically configure profile?") { |q| q.convert } 
    auto_config_bool = !auto_config_bool

    if auto_config_bool # if automatically configuring, won't ask for data just the cluster type and run from there
      cluster_type = prompt.select("What cluster type?", cluster_type_choices)
    end
  end

  # testing options

  testing_type_choices = %w(none basic full )
  testing_type = prompt.select("Perform testing?", testing_type_choices)

  case testing_type
  when "full"
    cram_testing = true
  when "basic"
    basic_testing = true
  end

  if cram_testing or basic_testing
    delete_on_success = prompt.no?("Delete on success?") { |q| q.convert } 
    delete_on_success = !delete_on_success # comes in as true its a no, but i want it to be false for no but still default to no
  end

  if cram_testing and !auto_config_bool
    cluster_type = prompt.select("What cluster type?", cluster_type_choices)
  end

  # actually launch the cluster launching process
  launch_code = "echo 'starting'; bash 0_parent.sh -g -i -p 'stackname=#{stack_name}' -p 'cnode_count=#{num_of_compute_nodes}' -p 'cluster_type=#{cluster_type}' -p 'login_instance_size=#{login_size}' -p 'compute_instance_size=#{compute_size}' -p 'login_disk_size=#{login_volume_size}' -p 'compute_disk_size=#{compute_volume_size}' -p 'platform=#{platform}' -p 'standalone=#{standalone}' -p 'cram_testing=#{cram_testing}' -p 'run_basic_tests=#{basic_testing}' -p 'cloud_sharepubkey=#{sharepubkey}' -p 'cloud_autoparsematch=#{autoparsematch}' -p 'delete_on_success=#{delete_on_success}' -p 'login_label=#{login_label}' -p 'login_prefix=#{login_prefix}' -p 'prefix_starts=#{prefix_starts}' -p 'autoparsematch=#{autoparsematch}' -p 'autoapplyrules=#{autoapplyrules}' -p 'auto_config_bool=#{auto_config_bool}' -p 'cnode_prefix=#{cnode_prefix}' -p 'userdata_broadcast=#{broadcast}' -p 'openstack_rc_filepath=#{openstack_rc_filepath}'" 

  exec ( launch_code ) 

  # end of class
end
