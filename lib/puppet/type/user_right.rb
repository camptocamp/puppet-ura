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

    newproperty(:sid, :array_matching => :all) do
        desc 'List of SIDs to allow for this right'

        def insync?(current)
            provider.sid_in_sync?(current, @should)
        end
    end
end
