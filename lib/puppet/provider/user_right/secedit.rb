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
        write_export(@parameters[:name], @parameters[:sid])
        @property_hash[:ensure] = :present
    end

    def destroy
        write_export(@parameters[:name], [])
        @property_hash[:ensure] = :absent
    end

    def sid
        @property_hash[:sid]
    end

    def sid=(value)
        write_export(@parameters[:name], value)
        @property_hash[:sid] = value
    end

    def in_file_path(right)
        File.join(Puppet[:vardir], 'secedit_export', "#{right}.txt")
    end

    def write_export(right, sid)
        dir = File.join(Puppet[:vardir], 'secedit_export')
        Dir.mkdir(dir) unless Dir.exist?(dir)

        File.open(in_file_path(right), 'rw') do |f|
          f.write <<-EOF
[Unicode]
Unicode=yes
[Privilege Rights]
#{right} = #{sid.join(',')}
[Version]
signature="$CHICAGO$"
Revision=1
          EOF
        end
    end

    def flush
        secedit('/configure', '/db', 'secedit.sdb', '/cfg', in_file_path(@parameters[:name]))
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
        # Once the file exists in UTF-8, secedit will also use UTF-8
        File.open(out_file_path, 'w') { |f| f.write('# Hello, windows') } unless File.file?(out_file_path)
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
