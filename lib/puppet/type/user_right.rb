Puppet::Type.newtype(:user_right) do
    @doc = <<-'EOT'
    Manage a Windows User Rights Assignment.
    EOT

    ensurable do
        defaultvalues

        defaultto { :present }
    end

    newparam(:name, :namevar => true) do
        desc 'The user right name'
    end

    def fragments
        # Collect fragments that target this resource by name or title.
        @fragments ||= catalog.resources.map { |resource|
            next unless resource.is_a?(Puppet::Type.type(:user_right_assignment))

            if resource[:right] == self[:name] || resource[:right] == title
                resource
            end
        }.compact
    end

    newproperty(:sid, :array_matching => :all) do
        desc 'List of SIDs to allow for this right'

        def should
            values = super

            fragments.each do |f|
                values << f[:sid]
            end

            values.compact
        end

        def insync?(current)
            provider.sid_in_sync?(current, @should)
        end
    end
end
