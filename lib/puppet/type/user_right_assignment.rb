Puppet::Type.newtype(:user_right_assignment) do
    @doc = <<-'EOT'
    Append users to a user_right resource.
    EOT

    newparam(:name, :namevar) do
        desc 'The mandatory namevar'
    end

    newparam(:right) do
        desc 'The right to append users to'
    end

    newparam(:sid) do
        desc 'List of SIDs to append to the right'
    end
end
