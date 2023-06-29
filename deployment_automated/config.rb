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

  openstack_rc_filepath = "setup/Ivan_testing-openrc.sh"

  stack_name = prompt.ask("Name of cluster?", required: true)  { |q| q.validate(/^[a-z][-a-z0-9]{1,61}[a-z0-9]$/)} # pattern satifies azure and aws requirements

  standalone = prompt.no?("Standalone cluster?") { |q| q.convert } # .convert maybe?
  standalone = !standalone

  platform_choices = %w(openstack aws azure)
  platform = prompt.select("Launch on what platform?", platform_choices)
  
  testing_type_choices = %w(basic cram none)
  testing_type = prompt.select("What testing?", testing_type_choices)

  case testing_type
  when "cram"
    cram_testing = true
  when "basic"
    basic_testing = true
  end

  if cram_testing or basic_testing
    delete_on_success = prompt.no?("Delete on success?") { |q| q.convert } 
    delete_on_success = !delete_on_success
  end

  if cram_testing 
    if standalone
      cluster_type_choices = %w(slurm jupyter)
    else
      cluster_type_choices = %w(slurm kubernetes)
    end
    cluster_type = prompt.select("What cluster type?", cluster_type_choices)
  end

  size_choices = %w(small medium large GPU)

  login_size = prompt.select("What instance size login node?", size_choices)
  login_volume_size = prompt.ask("What volume size login node? (GB)", default: "20") { |q| q.validate(/^[1-9][0-9]+/)} # accepts >10 GB
  
  unless standalone # if it isn't standalone then
    num_of_compute_nodes = prompt.ask("How many compute nodes?", default: "2") { |q| q.validate(/^10$|^[1-9]$/)} # accept only numbers from 1 to 10
    compute_size = prompt.select("What instance size compute nodes?", size_choices)
    compute_volume_size = prompt.ask("What volume size compute nodes? (GB)", default: "20") { |q| q.validate(/^[1-9][0-9]+/)} # accepts >10 GB
  end

  puts "Cloud init options:"
  sharepubkey = prompt.no?("Share Pub Key?") { |q| q.convert } 
  sharepubkey = !sharepubkey
  autoparsematch = prompt.ask("Auto Parse match regex:", default: "")


  #optional -b (basic tests)
  launch_code = "echo 'starting'; . #{openstack_rc_filepath}; source setup/openstack/bin/activate; bash 0_parent.sh -g -i -p 'stackname=#{stack_name}' -p 'cnode_count=#{num_of_compute_nodes}' -p 'cluster_type=#{cluster_type}' -p 'login_instance_size=#{login_size}' -p 'compute_instance_size=#{compute_size}' -p 'login_disk_size=#{login_volume_size}' -p 'compute_disk_size=#{compute_volume_size}' -p 'platform=#{platform}' -p 'standalone=#{standalone}' -p 'cram_testing=#{cram_testing}' -p 'run_basic_tests=#{basic_testing}' -p 'cloud_sharepubkey=#{sharepubkey}' -p 'cloud_autoparsematch=#{autoparsematch}' -p 'delete_on_success=#{delete_on_success}'" 

  exec ( launch_code ) 

  # end of class
end

# TODO: fix number validation, currently lets no answers through so commented it out since only i use this




