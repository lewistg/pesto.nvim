local M = {}

M.b = 'b'

local lib_c = require('lib_c.c')
M.bc = M.b .. lib_c.c

return M
