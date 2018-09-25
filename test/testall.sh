#!/bin/sh

lua loop/tests/models/proto.lua
lua loop/tests/models/base.lua
lua loop/tests/models/simple.lua
lua loop/tests/models/multiple.lua
lua loop/tests/models/cached.lua
#lua loop/tests/models/static.lua
lua loop/tests/models/hierarchy.lua

