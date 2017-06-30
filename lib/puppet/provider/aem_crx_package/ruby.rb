
Puppet::Type.type(:aem_crx_package).provide :ruby, parent: Puppet::Provider do

  mk_resource_methods

  confine feature: :xmlsimple
  confine feature: :crx_packmgr_api_client

  def self.require_libs
    require 'crx_packmgr_api_client'
    require 'xmlsimple'
  end

  def initialize(resource = nil)
    super(resource)
    @property_flush = {}
  end

  def upload
    @property_flush[:ensure] = :present
    Puppet.debug('aem_crx_package::ruby - Upload requested.')
  end

  def install
    @property_flush[:ensure] = :installed
    Puppet.debug('aem_crx_package::ruby - Install requested.')
  end

  def remove
    @property_flush[:ensure] = :absent
    Puppet.debug('aem_crx_package::ruby - Remove requested.')
  end

  def purge
    @property_flush[:ensure] = :purged
    Puppet.debug('aem_crx_package::ruby - Purge requested.')
  end

  def retrieve
    self.class.require_libs
    find_package
    Puppet.debug("aem_crx_package::ruby - Retrieve - Property Hash: #{@property_hash}")
    @property_hash[:ensure]
  end

  def flush
    return unless @property_flush[:ensure]
    Puppet.debug('aem_crx_package::ruby - Flushing out to AEM.')
    self.class.require_libs
    case @property_flush[:ensure]
    when :purged, :absent
      remove_package
    when :present
      if @property_hash[:ensure] == :absent
        upload_package
      else
        uninstall_package
      end
    when :installed
      install_package
    else
      raise(Puppet::ResourceError, "Unknown property flush value: #{@property_flush[:ensure]}")
    end
    find_package
    @property_flush.clear
  end

  private

  def build_cfg(port = nil, context_root = nil)
    config = CrxPackageManager::Configuration.new
    config.configure do |c|
      c.username = @resource[:username]
      c.password = @resource[:password]
      c.timeout = @resource[:timeout]
      c.host = "localhost:#{port}" if port
      c.base_path = "#{context_root}#{c.base_path}" if context_root
    end
    config
  end

  def build_client

    return @client if @client

    port = nil
    context_root = nil

    File.foreach(File.join(@resource[:home], 'crx-quickstart', 'bin', 'start-env')) do |line|
      match = line.match(/^PORT=(\S+)/) || nil
      port = match.captures[0] if match

      match = line.match(/^CONTEXT_ROOT='(\S+)'/) || nil
      context_root = match.captures[0] if match
    end

    config = build_cfg(port, context_root)
    @client = CrxPackageManager::DefaultApi.new(CrxPackageManager::ApiClient.new(config))
    @client
  end

  def find_package
    client = build_client
    retries = @resource[:retries]
    path = "/etc/packages/#{@resource[:group]}/#{@resource[:pkg]}-#{@resource[:version]}.zip"
    begin
      data = client.list(path: path, include_versions: true)
    rescue CrxPackageManager::ApiError => e
      Puppet.info("Unable to find package for Aem_crx_package[#{@resource[:pkg]}]: #{e}")
      will_retry = (retries -= 1) >= 0
      if will_retry
        Puppet.debug("Retrying package lookup; remaining retries: #{retries}")
        sleep 10
        retry
      end
      raise
    end

    found_pkg = find_version(data.results)
    Puppet.debug("aem_crx_package::ruby - Found package: #{found_pkg}")
    if found_pkg
      @property_hash[:group] = found_pkg.group
      @property_hash[:version] = found_pkg.version
      @property_hash[:ensure] = found_pkg.last_unpacked ? :installed : :present
    else
      @property_hash[:ensure] = :absent
    end
  end

  def find_version(ary)
    found_pkg = nil
    Puppet.debug("Looking for package version #{@resource[:version]}")
    ary && ary.each do |p|
      Puppet.debug("Checking package #{p}")
      found_pkg = p if p.version == @resource[:version]
      break if found_pkg
    end
    found_pkg
  end

  def upload_package
    client = build_client
    file = File.new(@resource[:source])
    result = client.service_post(file)
    raise_on_failure(result)
  end

  def install_package
    upload_package if @property_hash[:ensure] == :absent
    client = build_client
    result = client.service_exec('install', @resource[:pkg], @resource[:group], @resource[:version])
    raise_on_failure(result)
  end

  def uninstall_package
    client = build_client
    result = client.service_exec('uninstall', @resource[:pkg], @resource[:group], @resource[:version])
    raise_on_failure(result)
  end

  def remove_package
    if @property_hash[:ensure] == :installed && @property_flush[:ensure] == :purged
      uninstall_package
    end

    client = build_client
    result = client.service_exec('delete', @resource[:pkg], @resource[:group], @resource[:version])
    raise_on_failure(result)
  end

  def raise_on_failure(api_response)
    if api_response.is_a?(CrxPackageManager::ServiceExecResponse)
      raise(api_response.msg) unless api_response.success
    else
      hash = XmlSimple.xml_in(api_response, ForceArray: false, KeyToSymbol: true, AttrToSymbol: true)
      response = CrxPackageManager::ServiceResponse.new
      response.build_from_hash(hash)
      raise(response.response.status[:content]) unless response.response.status[:code].to_i == 200
    end
  end
end
