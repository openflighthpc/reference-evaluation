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

  platform_choices = %w(openstack aws azure)
  platform = prompt.select("Launch on what platform?", platform_choices)

  stack_name = prompt.ask("Name of cluster?", required: true) # aws says Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]*|arn:[-a-zA-Z0-9:/._+]*

  
  standalone = prompt.no?("Standalone cluster?") { |q| q.convert } # .convert maybe?
  standalone = !standalone

  cram_testing = prompt.no?("Cram testing?") { |q| q.convert } 
  cram_testing = !cram_testing

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
  login_volume_size = prompt.ask("What volume size login node? (GB)", default: "20") #{ |q| q.validate(/\^[0-9]+\$/) }
  
  unless standalone # if it isn't standalone then
    num_of_compute_nodes = prompt.ask("How many compute nodes?", default: "2") #{ |q| q.validate(/\^[0-9]+\$/) } # accept numbers only
    compute_size = prompt.select("What instance size compute nodes?", size_choices)
    compute_volume_size = prompt.ask("What volume size compute nodes? (GB)", default: "20") #{ |q| q.validate(/\^[0-9]+\$/) }
  end
  #optional -b (basic tests)
  launch_code = "echo 'starting'; . setup/Ivan_testing-openrc.sh; source setup/openstack/bin/activate; bash 0_parent.sh -g -i -p 'stackname=#{stack_name}' -p 'cnode_count=#{num_of_compute_nodes}' -p 'cluster_type=#{cluster_type}' -p 'login_instance_size=#{login_size}' -p 'compute_instance_size=#{compute_size}' -p 'login_disk_size=#{login_volume_size}' -p 'compute_disk_size=#{compute_volume_size}' -p 'platform=#{platform}' -p 'standalone=#{standalone}' -p 'cram_testing=#{cram_testing}' -p 'run_basic_tests=#{!cram_testing}'"

  exec ( launch_code ) 

  # end of class
end

# TODO: fix number validation, currently lets no answers through so commented it out since only i use this



