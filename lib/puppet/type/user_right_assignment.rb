Puppet::Type.newtype(:user_right_assignment) do
    @doc = <<-'EOT'
    Append users to a user_right resource.
    EOT

    newparam(:name, :namevar => true) do
        desc 'The mandatory namevar'
    end

    newparam(:right) do
        desc 'The right to append users to'

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

    newparam(:sid) do
        desc 'List of SIDs to append to the right'
    end
end
