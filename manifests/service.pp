# == Defines: aem::service
#
# Used to create service definitions for AEM instances.
#
# Based on Elastic Search service management.
#
define aem::service (
  $ensure           = 'present',
  $group            = 'aem',
  $home             = undef,
  $status           = 'enabled',
  $user             = 'aem',
  $service_options  = { 'TimeoutStopSec' => '4min', 'KillSignal' => 'SIGCONT', 'PrivateTmp' => true }

) {

  if $home == undef {
    fail('Home directory must be specified.')
  }

  assert_type(Stdlib::Absolutepath, $home)

  case $facts['os']['name'] {
    'CentOS', 'Fedora', 'RedHat' : {

      if versioncmp($facts['os']['release']['major'], '7') >= 0 {
        $provider      = 'systemd'
      } else {
        $provider      = 'init'
      }
    }
    'Amazon' : {
      # Amazon Linux 2023 dropped SysV/chkconfig entirely; AL1 and AL2 keep it.
      if versioncmp($facts['os']['release']['major'], '2023') >= 0 {
        $provider      = 'systemd'
      } else {
        $provider      = 'init'
      }
    }
    'Debian': {

      if versioncmp($facts['os']['release']['major'], '8') >= 0 {
        $provider      = 'systemd'
      } else {
        $provider      = 'init'
      }
    }
    'Ubuntu': {

      if versioncmp($facts['os']['release']['major'], '15') >= 0 {
        $provider      = 'systemd'
      } else {
        $provider      = 'init'
      }
    }
    default: {
      fail("'${module_name}' provides no service parameters for '${facts['os']['name']}'")
    }
  }

  case $provider {
    'init' : {
      aem::service::init { $name :
        ensure => $ensure,
        status => $status,
        group  => $group,
        home   => $home,
        user   => $user,
      }
    }
    'systemd' : {
      aem::service::systemd { $name :
        ensure          => $ensure,
        status          => $status,
        group           => $group,
        home            => $home,
        user            => $user,
        service_options => $service_options
      }
    }
    default : {
      fail("Unknown service provider: ${provider}")
    }
  }

}
