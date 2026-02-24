# dbf

A library for reading Visual FoxPro DBF tables.

## Install

1. Add `dbf` as a dependency to your `build.zig.zon`:

``` bash
zig fetch --save git+https://codeberg.org/Triast/dbf#master
```

2. Add `dbf` as a dependency to modules in your `build.zig`:

``` zig
const dbf = b.dependecy("dbf", .{});

exe.root_module.addImport("dbf", dbf.module("dbf"));
```

This library targets latest tagged release of zig, which is `0.15.2`.
