require_relative '../../../puppet_x/tragiccode/azure'

# Retrieves secrets from Azure's Key Vault.
Puppet::Functions.create_function(:'azure_key_vault::secret', Puppet::Functions::InternalFunction) do
  # @param vault_name Name of the vault in your Azure subscription.
  # @param secret_name Name of the secret to be retrieved.
  # @param api_versions_hash A Hash of the exact versions of the metadata_api_version and vault_api_version to use.
  # @param secret_version The version of the secret you want to retrieve.  This parameter is optional and if not passed the default behavior is to retrieve the latest version.
  # @return [Sensitive[String]] Returns the secret as a String wrapped with the Sensitive data type.
  dispatch :secret do
    cache_param
    required_param 'String', :vault_name
    required_param 'String', :secret_name
    required_param 'Hash',   :api_versions_hash
    optional_param 'String', :secret_version
    return_type 'Sensitive[String]'
  end

  def secret(cache, vault_name, secret_name, api_versions_hash, secret_version = '')
    Puppet.debug("vault_name: #{vault_name}")
    Puppet.debug("secret_name: #{secret_name}")
    Puppet.debug("secret_version: #{secret_version}")
    Puppet.debug("metadata_api_version: #{api_versions_hash['metadata_api_version']}")
    Puppet.debug("vault_api_version: #{api_versions_hash['vault_api_version']}")
    cache_hash = cache.retrieve(self)
    unless cache_hash.key?(:access_token)
      Puppet.debug("retrieving access token since it's not in the cache")
      cache_hash[:access_token] = TragicCode::Azure.get_access_token(api_versions_hash['metadata_api_version'])
    end
    secret_value = TragicCode::Azure.get_secret(
      vault_name,
      secret_name,
      api_versions_hash['vault_api_version'],
      cache_hash[:access_token],
      secret_version,
    )

    raise Puppet::Error, "The secret named #{secret_name} could not be found in a vault named #{vault_name}" if secret_value.nil?

    Puppet::Pops::Types::PSensitiveType::Sensitive.new(secret_value)
  end
end
