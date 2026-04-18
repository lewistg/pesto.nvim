describe('strip_csi_commands', function()
  local ansi_escape_codes = require('pesto.util.ansi_escape_codes')
  it('removes the CSI sequences from a string', function()
    local str = '\027[38;5;4mhello\027[0m'
    local stripped_str = ansi_escape_codes.strip_csi_commands(str)
    assert.are.same('hello', stripped_str)
  end)
end)
