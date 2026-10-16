local path =
  assert(package.searchpath("blink_cmp_fuzzy", package.cpath), "blink_cmp_fuzzy: library not found")
assert(path:sub(1, 1) == "/", "blink_cmp_fuzzy: relative library path")
return assert(package.loadlib(path, "luaopen_blink_cmp_fuzzy"))()
