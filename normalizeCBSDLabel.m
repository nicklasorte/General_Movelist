function labelOut = normalizeCBSDLabel(labelIn)
%normalizeCBSDLabel  Convert CBSD shorthand labels to display labels.
%
%   labelOut = normalizeCBSDLabel(labelIn)
%
%   Mappings:
%       "CatB", "BS"  -> "BaseStation"
%       "CatA", "AP"  -> "AccessPoint"
%       otherwise     -> original label (string)

    arguments
        labelIn {mustBeTextScalar}
    end

    labelIn = string(labelIn);  % normalize type

    % Define mapping groups
    baseStationAliases = ["CatB","BS"];
    accessPointAliases = ["CatA","AP"];

    if any(strcmpi(labelIn, baseStationAliases))
        labelOut = "BaseStation";
    elseif any(strcmpi(labelIn, accessPointAliases))
        labelOut = "AccessPoint";
    else
        labelOut = labelIn;  % pass through unchanged
    end
end