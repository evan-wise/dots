-- Author: Evan Wise
-- Revision Date: 2024-08-10
-- Purpose: Utility functions for neovim init.lua configuration file

local util = {}

function util.run_command(cmd, input)
  local tmp_input = os.tmpname()
  local tmp_output = os.tmpname()
  local tmp_error = os.tmpname()

  local input_file = io.open(tmp_input, 'w')
  if input_file == nil then
    print("Failed to open input file: " .. tmp_input)
    return
  end

  input_file:write(input)
  input_file:close()

  local exit_code = os.execute(cmd .. ' < ' .. tmp_input .. ' > ' .. tmp_output .. ' 2> ' .. tmp_error)

  local output_file = io.open(tmp_output, 'r')
  if output_file == nil then
    print("Failed to open output file: " .. tmp_output)
    return
  end
  local output = output_file:read('*a')
  output_file:close()

  local error_file = io.open(tmp_error, 'r')
  if error_file == nil then
    print("Failed to open error file: " .. tmp_error)
    return
  end
  local error = error_file:read('*a')
  error_file:close()

  os.remove(tmp_input)
  os.remove(tmp_output)
  os.remove(tmp_error)

  return exit_code, output, error
end

return util
