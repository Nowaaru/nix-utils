{attrsets, ...} @ lib: rec {
  # Iterate over a directory and apply
  # a function over the directory
  # contents.
  combAttrs = func: dir: attrsets.mapAttrs func (builtins.readDir dir);

  # Iterate over a directory and run a function
  # across all files. If this function returns null
  # then it is excluded from the output set. Otherwise,
  # transforms the value into the function's return.
  combFilter = filter: dir: 
    attrsets.filterAttrs (_: v: !builtins.isNull v) (builtins.mapAttrs filter (builtins.readDir dir));
}
