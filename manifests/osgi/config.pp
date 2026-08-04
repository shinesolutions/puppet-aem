# == Define: aem::osgi::config
#
# Configure osgi resource based on the specified type.
#
define aem::osgi::config(
  $ensure         = 'present',
  $group          = 'aem',
  $handle_missing = undef,
  $home           = undef,
  $password       = undef,
  $pid            = undef,
  $properties     = undef,
  $type           = undef,
  $user           = 'aem',
  $username       = undef,
){

  assert_type(Pattern[/^(present|absent)$/], $ensure) |$e, $a| {
    "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'."
  }

  if $ensure == 'present' {
    if $properties == undef {
      fail('Properties must contain at least one entry.')
    }

    if !($properties =~ Hash) {
      fail("Aem::Osgi::Config[${name}]: 'properties' must be a Hash of values")
    }
  }

  assert_type(Stdlib::Absolutepath, $home)

  assert_type(Pattern[/^(console|file)$/], $type) |$e, $a| {
    "${type} is not supported for type. Allowed values are 'console' and 'file'."
  }


  if $type == 'console' {

    if $username == undef {
      fail("Username must be specified if type == 'console'")
    }
    if $password == undef {
      fail("Password must be specified if type == 'console'")
    }
    if $ensure == 'present' {
      assert_type(Pattern[/^(merge|remove)$/], $handle_missing) |$e, $a| {
        "${handle_missing} is not supported for handle_missing. Allowed values are 'merge' and 'remove'."
      }
    }
  }

  case $type {
    'console' : {
      aem_osgi_config { $name :
        ensure         => $ensure,
        configuration  => $properties,
        handle_missing => $handle_missing,
        home           => $home,
        pid            => $pid,
        password       => $password,
        username       => $username,
      }
    }
    'file' : {
      aem::osgi::config::file { $name :
        ensure     => $ensure,
        group      => $group,
        home       => $home,
        pid        => $pid,
        properties => $properties,
        user       => $user,
      }
    }
    default : {
      fail("${type} is not supported for type. Allowed values are 'console' and 'file'.")
    }
  }
}
