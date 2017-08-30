################################################################################
# Time-stamp: <Wed 2017-08-30 15:02 svarrette>
#
# File::      <tt>config.pp</tt>
# Author::    UL HPC Team (hpc-sysadmins@uni.lu)
# Copyright:: Copyright (c) 2017 UL HPC Team
# License::   Apache-2.0
#
# ------------------------------------------------------------------------------
# == Class: slurm::config
#
# This PRIVATE class handles the configuration of SLURM daemons
# More details on <https://slurm.schedmd.com/slurm.conf.html#lbAN> and also on
# - https://slurm.schedmd.com/slurm.conf.html
# - https://slurm.schedmd.com/slurmdbd.conf.html
# - https://slurm.schedmd.com/topology.conf.html
# - https://slurm.schedmd.com/cgroup.conf.html
#
class slurm::config { #}inherits slurm {

  include ::slurm
  include ::slurm::params


  # Prepare the directory structure
  if $slurm::ensure == 'present' {
    file { $slurmdirs:
        ensure  => 'directory',
        owner   => $slurm::params::username,
        group   => $slurm::params::group,
        mode    => $slurm::params::configdir_mode,
        before  => File[$slurm::params::configfile]
    }
    File[$slurm::configdir] -> File[$pluginsdir]
  }
  else {
    file { $slurmdirs:
        ensure => $slurm::ensure,
        force  => true,
    }
    File[$pluginsdir] -> File[$slurm::configdir]
  }








  # Now let's deal with slurm.conf
  $slurm_content = $slurm::content ? {
    undef   => $slurm::source ? {
      undef   => $slurm::target ? {
        undef   => template('slurm/slurm.conf.erb'),
        default => $slurm::content,
      },
    default => $slurm::content
    },
  default => $slurm::content,
  }
  $ensure = $slurm::target ? {
    undef   => $slurm::ensure,
    default => 'link',
  }
  $pluginsdir = "${slurm::configdir}/${slurm::params::pluginsdir}"
  $slurmdirs = [
    $slurm::configdir,
    $slurm::params::logdir,
    #$slurm::params::piddir,
    $pluginsdir,
  ]


  # Now add the configuration files
  include ::slurm::config::cgroup
  include ::slurm::config::gres
  include ::slurm::config::topology

  # Main slurm.conf
  $filename = "${slurm::configdir}/${slurm::params::configfile}"
  file { $slurm::params::configfile:
    ensure  => $ensure,
    path    => $filename,
    owner   => $slurm::username,
    group   => $slurm::group,
    mode    => $slurm::params::configfile_mode,
    content => $slurm_content,
    source  => $slurm::source,
    target  => $slurm::target,
    tag     => 'slurm::configfile',
    require => File[$slurm::configdir],
  }

  # Eventually, add the plugins
  if member($slurm::build_with, 'lua') {
    include ::slurm::plugins::lua
  }


}
