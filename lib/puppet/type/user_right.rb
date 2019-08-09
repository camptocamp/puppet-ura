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

        validate do |value|
            unless SecurityPolicy.valid_lsp?(value) or SecurityPolicy.find_mapping_from_policy_name(value)
                raise ArgumentError, "Invalid Policy name: #{value}"
            end
        end

        munge do |value|
            if value.to_s =~ /\s+/
                begin
                    policy_hash = SecurityPolicy.find_mapping_from_policy_desc(value)
                    value = policy_hash[:name]
                rescue KeyError => e
                    fail(e.message)
                end
            end
            value.downcase
        end
    end

    newproperty(:sid, :array_matching => :all) do
        desc 'List of SIDs to allow for this right'

        def fragments
            # Collect fragments that target this resource by name or title.
            @fragments ||= resource.catalog.resources.map { |res|
                next unless res.is_a?(Puppet::Type.type(:user_right_assignment))

                if res[:right] == @resource[:name] || res[:right] == @resource[:title]
                    res
                end
            }.compact
        end

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
