function ind = nameToCompartmentIndex(m, names, allow_missing)

if nargin < 3
    allow_missing = [];
end

if ischar(names)
    names = {names};
end

if isempty(allow_missing)
    allow_missing = true;
end

ind = lookupmember(names, {m.Compartments.Name});

if ~allow_missing && any(vec(ind) == 0)
    error('KroneckerBio:UnknownCompartmentName', 'Compartment "%s" not found', names{find(~ind,1)})
end
