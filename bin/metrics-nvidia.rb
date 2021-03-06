#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   nvidia-metrics
#
# DESCRIPTION:
#   This plugin uses nvidia-smi to collect basic metrics, produces
#   Graphite formated output.
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: socket
#   nvidia-smi
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Cedric <cedric.grun@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'

class EntropyGraphite < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.nvidia"

  def run
    # get the slots for labelling multiple GPUs
    pci_slots = `nvidia-smi --query-gpu=pci.bus --format=csv,noheader`.scan(/^.+$/)

    metrics = {}
    keys = ['temperature.gpu', 'fan.speed', 'memory.used', 'memory.total', 'memory.free', 'utilization.memory', 'utilization.gpu', 'power.draw']
    keys.each do |key|
      metrics[key] = `nvidia-smi --query-gpu=#{key} --format=csv,noheader`.scan(/\d+\.?\d*/)
    end

    timestamp = Time.now.to_i

    # for every unit output every metric

    pci_index = 0

    pci_slots.each do
      metrics.each do |key, value|
        output [[config[:scheme], pci_slots[pci_index]].join('.bus'), key].join('.'), value[pci_index], timestamp
      end
      pci_index += 1
    end
    ok
  end
end
