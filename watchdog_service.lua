#!/usr/bin/env lua

require("batctl")
require("string")

--[[

  The purpose of the script is to monitor
  system critical resources and restart services
  or perform a hardware reset if necessary.
  
  Eventually this script should monitor:
    kernel watchdog
    abnormal system load
    cron daemon
    ssh daemon
    tunneldigger
    batman-adv interfaces

--]]

SLEEP_INTERVAL_SECONDS = 5

COMMAND_SLEEP  = "sleep"
COMMAND_UPTIME = "uptime"

SERVICE_NAME_CRON         = "cron"
SERVICE_NAME_SSH          = "sshd"
SERVICE_NAME_TUNNELDIGGER = "tunneldigger"

function get_cpu_load_averages()
  
  function parse_float(str)
    return string.match(str, '(%d+).%d+') + (string.match(str, '%d+.(%d+)') * 0.01)
  end
  
  load_cmd = io.popen(COMMAND_UPTIME)
  load_str = load_cmd:read("*l")
  
  one_m = parse_float(string.match(load_str, '.*load%saverage:%s(%d+.%d+),%s%d+.%d+,%s%d+.%d+'))
  five_m = parse_float(string.match(load_str, '.*load%saverage:%s%d+.%d+,%s(%d+.%d+),%s%d+.%d+'))
  fifteen_m = parse_float(string.match(load_str, '.*load%saverage:%s%d+.%d+,%s%d+.%d+,%s(%d+.%d+)'))
  
  load_cmd:close()
  return {[1] = one_m, [5] = five_m, [15] = fifteen_m}
end

function is_process_running(name_str)
  proc_found = false
  proc_ls = io.popen('ls -l /proc/ | grep [0-9][0-9]:[0-9][0-9]\\ [0-9]')
  for proc_str in proc_ls:lines() do
    proc_id = string.match(proc_str, '.*%d+:%d+%s(%d+)')
    proc_status = io.popen('2>&1 cat /proc/' .. proc_id .. '/status')
    proc_name = proc_status:read("*l")
    if not (proc_name == nil) then
      if string.match(proc_name, 'Name:%s+(.+)$') == name_str then
        proc_found = true
        break
      end
    end
    proc_status:close()
  end
  proc_ls:close()
  
  return proc_found
end

function is_interface_meshing(iface_name)
  iface_found = false
  result = get_interface_settings()
  if result.status == BATCTL_STATUS_SUCCESS then
    for key, iface in pairs(result.data) do
      if iface.name == iface_name and iface.status == "active" then
        iface_found = true
        break
      end
    end
  end
  
  return iface_found
end

function do_stuff()
  
  while true do
    cpu_loads = get_cpu_load_averages()
    print("five minute load average: " .. cpu_loads[5])
  
    if is_process_running(SERVICE_NAME_CRON) then
      print("cron is running :)")
    else
      print("cron is not running! D:")
    end
    
    if is_process_running(SERVICE_NAME_SSH) then
      print("ssh is running :)")
    else
      print("ssh is not running! D:")
    end
    
    if is_process_running(SERVICE_NAME_TUNNELDIGGER) then
      print("tunneldigger is running :)")
    else
      print("tunneldigger is not running! D:")
    end
    
    if is_interface_meshing("adhoc0") then
      print("meshing on adhoc0 :)")
    else
      print("not meshing on adhoc0! D:")
    end
    
    sleepcmd = io.popen(COMMAND_SLEEP .. " " .. SLEEP_INTERVAL_SECONDS)
    sleepcmd:close()
  end
  
end

rootchk = io.popen('id -u')
if not (rootchk:read("*n") == 0) then
  rootchk:close()
  print("this script must be run as root")
else
  do_stuff()
end