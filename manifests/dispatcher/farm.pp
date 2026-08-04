# == Define: aem::dispatcher::farm
#
# Configure a Dispatcher instance.
define aem::dispatcher::farm(
  $ensure              = 'present',
  $allow_authorized    = undef,
  $allowed_clients     = $::aem::dispatcher::params::allowed_clients,
  $auth_checker        = undef,
  $cache_headers       = undef,
  $cache_rules         = $::aem::dispatcher::params::cache_rules,
  $cache_ttl           = undef,
  $client_headers      = $::aem::dispatcher::params::client_headers,
  $docroot             = undef,
  $failover            = undef,
  $filters             = $::aem::dispatcher::params::filters,
  $grace_period        = undef,
  $health_check_url    = undef,
  $ignore_parameters   = undef,
  $invalidate          = undef,
  $invalidate_handler  = undef,
  $priority            = $::aem::dispatcher::params::priority,
  $propagate_synd_post = undef,
  $renders             = $::aem::dispatcher::params::renders,
  $retries             = undef,
  $retry_delay         = undef,
  $serve_stale         = undef,
  $session_management  = undef,
  $stat_file           = undef,
  $stat_files_level    = undef,
  $statistics          = undef,
  $sticky_connections  = undef,
  $unavailable_penalty = undef,
  $vanity_urls         = undef,
  $virtualhosts        = $::aem::dispatcher::params::virtualhosts
) {

  # Required dispatcher class because it is used by parameter defaults
  if ! defined(Class['aem::dispatcher']) {
    fail('You must include the aem::dispatcher base class before using any dispatcher class or defined resources')
  }

  assert_type(Pattern[/^(present|absent)$/], $ensure) |$e, $a| {
    "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'."
  }

  if $allow_authorized {
    assert_type(Integer[0, 1], $allow_authorized)
  }

  if $allowed_clients =~ Array {
    assert_type(Hash, $allowed_clients[0])
    $_allowed_clients = $allowed_clients
  } else {
    assert_type(Hash, $allowed_clients)
    $_allowed_clients = [$allowed_clients]
  }

  if $auth_checker {
    assert_type(Hash, $auth_checker)

    if !has_key($auth_checker, 'url') {
      fail('Auth checker url is not specified.')
    }

    if !has_key($auth_checker, 'filter') {
      fail('Auth checker filter are not specified.')
    } else {
      if !($auth_checker['filter'] =~ Array) {
        fail('Auth checker filter must be an array.')
      }
      assert_type(Hash, $auth_checker['filter'][0])
    }

    if !has_key($auth_checker, 'headers') {
      fail('Auth checker headers are not specified.')
    } else {
      if !($auth_checker['headers'] =~ Array) {
        fail('Auth checker headers must be an array.')
      }
      assert_type(Hash, $auth_checker['headers'][0])
    }
  }

  if $cache_headers {
    if $cache_headers =~ Array {
      $_cache_headers = $cache_headers
    } else {
      $_cache_headers = [$cache_headers]
    }
  }

  if $cache_rules =~ Array {
    assert_type(Hash, $cache_rules[0])
    $_cache_rules = $cache_rules
  } else {
    assert_type(Hash, $cache_rules)
    $_cache_rules = [$cache_rules]
  }

  if $cache_ttl {
    assert_type(Integer[0, 1], $cache_ttl)
  }

  if $client_headers =~ Array {
    $_client_headers = $client_headers
  } else {
    $_client_headers = [$client_headers]
  }

  assert_type(Stdlib::Absolutepath, $docroot)

  if $failover {
    assert_type(Integer[0, 1], $failover)
  }

  if $filters =~ Array {
    assert_type(Hash, $filters[0])
    $_filters = $filters
  } else {
    assert_type(Hash, $filters)
    $_filters = [$filters]
  }

  if $grace_period {
    assert_type(Integer[1], $grace_period)
  }

  if $health_check_url {
    assert_type(String, $health_check_url)
  }

  if $ignore_parameters {
    if $ignore_parameters =~ Array {
      assert_type(Hash, $ignore_parameters[0])
      $_ignore_parameters = $ignore_parameters
    } else {
      assert_type(Hash, $ignore_parameters)
      $_ignore_parameters = [$ignore_parameters]
    }
  }

  if $invalidate_handler {
    assert_type(Stdlib::Absolutepath, $invalidate_handler)
  } elsif $invalidate == undef {
    $_invalidate = $::aem::dispatcher::params::invalidate
  } else {

    if $invalidate =~ Array {
      assert_type(Hash, $invalidate[0])
      $_invalidate = $invalidate
    } else {
      assert_type(Hash, $invalidate)
      $_invalidate = [$invalidate]
    }
  }

  if $priority {
    if $priority.is_a(Integer) {
      assert_type(Integer[0, 99], $priority)
      if $priority < 10 {
        $priority_string = "0${priority}"
      }
      else {
        $priority_string = $priority
      }
    }
    else {
      fail('Priority should be a valid Integer from 0 to 99')
    }

  }
  else {
    $priority_string = '00'
  }

  if $propagate_synd_post {
    assert_type(Integer[0, 1], $propagate_synd_post)
  }

  if $renders =~ Array {
    assert_type(Hash, $renders[0])
    $_renders = $renders
  } else {
    assert_type(Hash, $renders)
    $_renders = [$renders]
  }

  if $retries {
    assert_type(Integer[1], $retries)
  }

  if $retry_delay {
    assert_type(Integer[1], $retry_delay)
  }

  if $serve_stale {
    assert_type(Integer[0, 1], $serve_stale)
  }

  if $session_management {
    if $allow_authorized == 1 {
      fail('Allow authorized and session management are mutually exclusive.')
    }
    assert_type(Hash, $session_management)
    if !has_key($session_management, 'directory') {
      fail('Session management directory is not specified.')
    } else {
      assert_type(Stdlib::Absolutepath, $session_management['directory'])
    }
    if has_key($session_management, 'encode') {
      assert_type(Pattern[/^(md5|hex)$/], $session_management['encode']) |$e, $a| {
        "${session_management['encode']} is not supported for session_management['encode']. Allowed values are 'md5' and 'hex'."
      }
    }
    if has_key($session_management, 'timeout') {
      assert_type(Integer[0], $session_management['timeout'])
    }
  }

  if $stat_file {
    assert_type(Stdlib::Absolutepath, $stat_file)
  }

  if $stat_files_level {
    assert_type(Integer[0], $stat_files_level)
  }

  if $statistics {
    if $statistics =~ Array {
      assert_type(Hash, $statistics[0])
      $_statistics = $statistics
    } else {
      assert_type(Hash, $statistics)
      $_statistics = [$statistics]
    }
  }

  if $sticky_connections {
    if $sticky_connections =~ Array {
      assert_type(String, $sticky_connections[0])
    } else {
      assert_type(String, $sticky_connections)
    }
  }

  if $unavailable_penalty {
    assert_type(Integer[1], $unavailable_penalty)
  }

  if $vanity_urls {
    assert_type(Hash, $vanity_urls)
    if !has_key($vanity_urls, 'file') {
      fail('Vanity Urls cache file is not specified.')
    } else {
      assert_type(Stdlib::Absolutepath, $vanity_urls['file'])
      assert_type(Integer[0], $vanity_urls['delay'])
    }
  }

  if !($virtualhosts =~ Array) {
    $_virtualhosts = [$virtualhosts]
  } else {
    $_virtualhosts = $virtualhosts
  }

  if $ensure == 'present' {
    file { "${::aem::dispatcher::params::farm_path}/dispatcher.${priority_string}-${name}.inc.any" :
      ensure  => $ensure,
      content => template("${module_name}/dispatcher/dispatcher.any.erb"),
      notify  => Service[$::apache::service_name],
    }
  } else {
    file { "${::aem::dispatcher::params::farm_path}/dispatcher.${priority_string}-${name}.inc.any" :
      ensure => $ensure,
      notify => Service[$::apache::service_name],
    }
  }

}
