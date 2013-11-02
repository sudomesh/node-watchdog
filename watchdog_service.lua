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

function get_cpu_load_averages()
  
  function parse_float(str)
    return string.match(str, '(%d+).%d+') + (string.match(str, '%d+.(%d+)') * 0.01)
  end
  
  load_cmd = io.popen('uptime')
  load_str = load_cmd:read("*L")
  
  one_m = parse_float(string.match(load_str, '.*load%saverage:%s(%d+.%d+),%s%d+.%d+,%s%d+.%d+'))
  five_m = parse_float(string.match(load_str, '.*load%saverage:%s%d+.%d+,%s(%d+.%d+),%s%d+.%d+'))
  fifteen_m = parse_float(string.match(load_str, '.*load%saverage:%s%d+.%d+,%s%d+.%d+,%s(%d+.%d+)'))
  
  return {one_m, five_m, fifteen_m}
end

rootchk = io.popen('id -u')
if not (rootchk:read("*n") == 0) then
  print("this script must be run as root")
else
  
  
  cpu_load = get_cpu_load_averages(io.popen('uptime'))
  print("load average of one minute: " .. cpu_load[1] .. ", five minutes: " .. cpu_load[2] .. ", fifteen minutes: " .. cpu_load[3])
  
  -- get an array of batman-adv managed interfaces
  result = get_interface_settings()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("batman-adv currently managing " .. #result.data .. " interfaces.")
    for key, iface in pairs(result.data) do
      print(iface.name .. ': ' .. iface.status)
    end
  else
    print("error! " .. result.data)
  end

  -- get an array of all known batman-adv network originators
  result = get_originators()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("\nthere are " .. #result.data .. " originators known to the network.")
    for key, orig in pairs(result.data) do
      print(orig.address .. ' last seen ' .. orig.last_seen_ms .. 'ms ago')
    end
  else
    print("error! " .. result.data)
  end

  -- get an array of all known batman-adv gateways
  result = get_gateway_list()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("\nthere are " .. #result.data .. " gateways known to the network.")
    for key, gateway in pairs(result.data) do
      print(gateway.address .. ' class: ' .. gateway.class)
    end
  else
    print("error! " .. result.data)
  end

  -- get the originator interval
  result = get_originator_interval_ms()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("\noriginator interval is: " .. result.data)
  else
    print("error! " .. result.data)
  end

  -- get the gateway mode
  result = get_gateway_mode()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("\ngateway mode is: " .. result.data)
  else
    print("error! " .. result.data)
  end

  -- get packet aggregation
  result = get_packet_aggregation()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("\npacket aggregation is: " .. result.data)
  else
    print("error! " .. result.data)
  end

  -- get bonding mode
  result = get_bonding_mode()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("\nbonding mode is: " .. result.data)
  else
    print("error! " .. result.data)
  end

  -- get fragmentation mode
  result = get_fragmentation_mode()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("\nfragmentation mode is: " .. result.data)
  else
    print("error! " .. result.data)
  end

  -- get ap isolation mode
  result = get_ap_isolation_mode()
  if result.status == BATCTL_STATUS_SUCCESS then
    print("\nisolation mode is: " .. result.data)
  else
    print("error! " .. result.data)
  end
end