#
# Unit tests for designate::api
#
require 'spec_helper'

describe 'designate::api' do
  let :params do
    {
      :keystone_password => 'passw0rd',
      :keystone_host     => '10.0.0.42',
      :keystone_port     => '35357',
      :keystone_protocol => 'https',
      :keystone_tenant   => '_services_',
      :keystone_user     => 'designate',
    }
  end

  shared_examples 'designate-api' do
    context 'with default parameters' do
      it 'installs designate-api package and service' do
        is_expected.to contain_service('designate-api').with(
          :name      => platform_params[:api_service_name],
          :ensure    => 'running',
          :enable    => 'true',
          :tag       => ['openstack', 'designate-service'],
        )
        is_expected.to contain_package('designate-api').with(
          :name      => platform_params[:api_package_name],
          :ensure    => 'present',
          :tag       => ['openstack', 'designate-package'],
        )
      end

      it 'configures designate-api with default parameters' do
        is_expected.to contain_designate_config('service:api/auth_strategy').with_value('noauth')
        is_expected.to contain_designate_config('service:api/enable_api_v1').with_value(true)
        is_expected.to contain_designate_config('service:api/enable_api_v2').with_value(false)
        is_expected.to contain_designate_config('service:api/enable_api_admin').with_value(false)
        is_expected.to contain_designate_config('service:api/api_host').with_value('0.0.0.0')
        is_expected.to contain_designate_config('service:api/api_port').with_value('9001')
        is_expected.to contain_designate_config('service:api/api_base_uri').with_value('<SERVICE DEFAULT>')
        is_expected.to_not contain_designate__keystone__authtoken('designate_config')
      end

      context 'when using auth against keystone' do
        before { params.merge!(:auth_strategy => 'keystone') }
        it 'configures designate-api with keystone auth strategy' do
          is_expected.to contain_designate_config('service:api/auth_strategy').with_value('keystone')
        end
      end

      context 'when using memcached with  keystone auth' do
        before do
          params.merge!(
            :keystone_memcached_servers => [ '127.0.0.1:11211', '127.0.0.1:11212' ],
            :auth_strategy => 'keystone',
          )
        end
        it 'configures designate-api with keystone memcached servers' do
            is_expected.to contain_designate_config('keystone_authtoken/memcached_servers').with_value('127.0.0.1:11211,127.0.0.1:11212')
        end
      end
    end

    context 'with custom package name' do
      before do
        params.merge!({ :api_package_name => 'designate-api-custom-name' })
      end

      it 'configures using custom name' do
        is_expected.to contain_package('designate-api').with(
          :name      => 'designate-api-custom-name',
          :ensure    => 'present',
          :tag       => ['openstack', 'designate-package'],
        )
      end
    end

    context 'with backwards compatible parameters' do
      let :params do
        {
          :auth_strategy     => 'keystone',
          :keystone_password => 'passw0rd',
          :keystone_host     => '10.0.0.42',
          :keystone_port     => '35357',
          :keystone_protocol => 'https',
          :keystone_tenant   => '_services_',
          :keystone_user     => 'designate',
        }
      end

      it 'configures designate-api with correct parameters' do
        is_expected.to contain_designate_config('service:api/auth_strategy').with_value('keystone')
        is_expected.to contain_designate_config('service:api/enable_api_v1').with_value(true)
        is_expected.to contain_designate_config('service:api/enable_api_v2').with_value(false)
        is_expected.to contain_designate_config('service:api/enable_api_admin').with_value(false)
        is_expected.to contain_designate_config('service:api/api_host').with_value('0.0.0.0')
        is_expected.to contain_designate_config('service:api/api_port').with_value('9001')
        is_expected.to contain_designate_config('service:api/api_base_uri').with_value('<SERVICE DEFAULT>')
        is_expected.to contain_designate_config('keystone_authtoken/auth_url').with_value('https://10.0.0.42:35357')
        is_expected.to contain_designate_config('keystone_authtoken/auth_uri').with_value('https://10.0.0.42:35357')
        is_expected.to contain_designate_config('keystone_authtoken/project_name').with_value('_services_')
        is_expected.to contain_designate_config('keystone_authtoken/username').with_value('designate')
        is_expected.to contain_designate_config('keystone_authtoken/password').with_value('passw0rd')

      end

    end

  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      let(:platform_params) do
        case facts[:osfamily]
        when 'Debian'
          {
            :api_package_name => 'designate-api',
            :api_service_name => 'designate-api'
          }
        when 'RedHat'
          {
            :api_package_name => 'openstack-designate-api',
            :api_service_name => 'designate-api'
          }
        end
      end
      it_behaves_like 'designate-api'
    end
  end
end
