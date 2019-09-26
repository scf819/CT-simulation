function y = uint8cast(x, type)
% cast viarible to uint8

switch type
    case {'double', 'single', 'int64', 'uint64', 'int32', 'uint32', ...
          'int16', 'uint16', 'int8', 'uint8'}
        y = typecast(x, type);
    case 'char'
        % y = char(typecast(x, 'uint16'));
        y = char(x);
    case {'logical', 'bool'}
        % y = rot90(dec2bin(x, 8)=='1');
        y = logical(x);
    otherwise
        y = [];
end