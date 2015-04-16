require 'spec_helper'

describe 'corosync::pcsd' do

  let :default_params do
    {
      :hacluster_password => 'somepassword',
      :hacluster_salt     => 'somesalt',
    }
  end
  let :params do
    default_params
  end

  # corosync::pcsd class depends on existing corosync configuration
  let :pre_condition do
    "file {'/etc/corosync/corosync.conf': ensure => present }"
  end

  shared_examples_for 'corosync::pcsd' do
    it { is_expected.to compile }

    it { is_expected.to contain_user('hacluster').with(
      :system   => true,
      :shell    => '/sbin/nologin',
      # sha-512 passwd entry of "somepassword" salted with "somesalt"
      :password => '$6$somesalt$a6TNVzqJscGfWGRxg09hlKQmgYhKWNvzXaN5ZzibynRz1JZpWam43pb/xMtCDdh3dkCE8F3FIP.ovFUAaErmz0',
      :ensure   => 'present',
    )}

    it { is_expected.to contain_service('pcsd').with(
      :ensure => 'running',
      :enable => true,
    )}

    it {
      is_expected.to contain_exec('pcs cluster auth').
        with(
          :command   => "/usr/sbin/pcs cluster auth -u 'hacluster' -p 'somepassword'",
          :unless    => "/usr/sbin/pcs cluster pcsd-status",
          :timeout   => 30,
          :tries     => 30,
          :try_sleep => 10,
        ).
        that_requires("User[hacluster]").
        that_requires("Service[pcsd]").
        that_requires("File[/etc/corosync/corosync.conf]").
        that_subscribes_to("File[/etc/corosync/corosync.conf]")
    }

    context 'with overriden defaults' do
      let :params do
        default_params.merge({
          :hacluster_user     => "pcs",
          :pcs_auth_timeout   => 20,
          :pcs_auth_tries     => 60,
          :pcs_auth_try_sleep => 5,
        })
      end

      it { is_expected.to contain_user('pcs') }

      it { is_expected.not_to contain_user('hacluster') }

      it {
        is_expected.to contain_exec('pcs cluster auth').
          with(
            :command   => "/usr/sbin/pcs cluster auth -u 'pcs' -p 'somepassword'",
            :timeout   => 20,
            :tries     => 60,
            :try_sleep => 5,
          ).
          that_requires("User[pcs]")
      }

      it { is_expected.not_to contain_exec('pcs cluster auth').
        that_requires("User[hacluster]") }
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily       => 'Debian',
        :processorcount => '3',
        :ipaddress      => '127.0.0.1' }
    end

    it_configures 'corosync::pcsd'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily       => 'RedHat',
        :processorcount => '3',
        :ipaddress      => '127.0.0.1' }
    end

    it_configures 'corosync::pcsd'
  end
end
