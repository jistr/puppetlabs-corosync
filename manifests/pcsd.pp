# == Class: corosync::pcsd
#
# This class will set up pcs daemon for synchronizing corosync
# configuration across all nodes in the cluster. It depends on
# corosync.conf file having been generated, so it is recommended to
# use it together with the corosync class.
#
# === Parameters
#
# [*hacluster_password*]
#   Password for the user which is used by pcsd to authenticate
#   on cluster nodes.
#
# [*hacluster_salt*]
#   Password salt for the user which is used by pcsd to authenticate
#   on cluster nodes.
#
# [*hacluster_user*]
#   (optional) Name of the user which is used by pcsd to authenticate
#   on cluster nodes.
#
# [*pcs_auth_timeout*]
#   (optional) Timeout for the pcs cluster auth command.
#
# [*pcs_auth_tries*]
#   (optional) Max number of tries for the pcs cluster auth command to succeed.
#
# [*pcs_auth_timeout*]
#   (optional) Delay between tries of the pcs cluster auth command.
#
# === Examples
#
#  class { 'corosync::pcsd':
#    hacluster_password => 'somepassword',
#    hacluster_salt     => 'somesalt',
#  }
#
class corosync::pcsd(
  $hacluster_password,
  $hacluster_salt,

  $hacluster_user                      = $::corosync::params::hacluster_user,
  $pcs_auth_timeout                    = $::corosync::params::pcs_auth_timeout,
  $pcs_auth_tries                      = $::corosync::params::pcs_auth_tries,
  $pcs_auth_try_sleep                  = $::corosync::params::pcs_auth_try_sleep,
) inherits ::corosync::params {

  user { $hacluster_user:
    system   => true,
    password => pw_hash($hacluster_password, 'sha-512', $hacluster_salt),
    shell    => '/sbin/nologin',
    ensure   => present,
  }

  service { 'pcsd':
    ensure  => running,
    enable  => true,
  }

  exec { 'pcs cluster auth':
    # --local means that when run on node A, it will trigger auth of A
    # against B but not B against A. Node B will be responsible for
    # setting up its own auth using the same command.
    command   => "/usr/sbin/pcs cluster auth -u '${hacluster_user}' -p '${hacluster_password}' --local",
    unless    => "/usr/sbin/pcs cluster pcsd-status",
    timeout   => $pcs_auth_timeout,
    tries     => $pcs_auth_tries,
    try_sleep => $pcs_auth_try_sleep,
    require   => [ User[$hacluster_user],
                   Service['pcsd'],
                   File['/etc/corosync/corosync.conf'] ],
    subscribe => File['/etc/corosync/corosync.conf'],
  }
}
