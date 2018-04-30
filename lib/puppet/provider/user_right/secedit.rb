require 'puppet/util/windows'
#require File.expand_path('../../../util/ini_file', __FILE__)
# See how to make this work properly...
require File.expand_path('../../../../../spec/fixtures/modules/inifile/lib/puppet/util/ini_file', __FILE__)

Puppet::Type.type(:user_right).provide(:secedit) do
    defaultfor :osfamily => :windows
    confine :osfamily => :windows

    commands :secedit => 'secedit.exe'

    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        # Same as modify, just create the file and flush
    end

    def destroy
        # Same as modify, SID is empty
    end

    def sid_in_sync?(current, should)
        return false unless current

        current_users = Puppet::Util::Windows::ADSI::Group.name_sid_hash(current)
        specified_users = Puppet::Util::Windows::ADSI::Group.name_sid_hash(should)

        current_sids = current_users.keys.to_a
        specified_sids = specified_users.keys.to_a

        (specified_sids & current_sids) == specified_sids
    end

    def self.prefetch(resources)
        instances.each do |right|
            resources.select { |title, res|
                res[:name].downcase == right.get(:name).downcase
            }.map { |name, res|
                res.provider = right
            }
        end
    end

    def self.instances
        out_file_path = File.join(Puppet[:vardir], 'secedit_import.txt')
        secedit('/export', '/cfg', out_file_path, '/areas', 'user_rights')
        ini = Puppet::Util::IniFile.new(out_file_path, '=')
        ini.get_settings('Privilege Rights').map { |k, v|
            new({
                :name   => k,
                :ensure => :present,
                :sid    => v.split(','),
            })
        }
    end
end
