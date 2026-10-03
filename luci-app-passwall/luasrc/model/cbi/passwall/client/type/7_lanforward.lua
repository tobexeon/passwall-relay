-- [[ LAN Forward ]]
local m, s1 = ...
local type_name = "LANForward"

s1.fields["type"]:value(type_name, translate("LAN Forward"))

if s1.val["type"] and s1.val["type"] ~= type_name then
	return
end

local s = NamedSection(m, arg[1], "tmp_" .. s1.sectiontype)
s.parent = s1
s.type_name = type_name
s.option_prefix = "lanforward_"
api.set_type_cbi(s)

o = s:option(Value, "address", translate("Target Device Address (LAN IP)"))
o.datatype = "ip4addr"
o.rmempty = false
o.description = translate("The LAN IP of the device that actually does the proxying (e.g. 10.10.10.10). The kernel (iptables/nftables) will DNAT the proxied traffic directly to this device:port, no local proxy client is started on this router.")

o = s:option(Value, "port", translate("Target Device Port"))
o.datatype = "port"
o.rmempty = false
o.description = translate("The transparent proxy port on the target device. The target device must be able to transparently handle the forwarded traffic (recover the original destination).")

o = s:option(ListValue, "protocol", translate("Forward Protocol"))
o:value("socks", "Socks5")
o:value("http", "HTTP")
o.default = "socks"
o.description = translate("Only used when this node is used in user-space scenarios (e.g. shunt rules, per-ACL nodes). The kernel LAN-forward path ignores this field and forwards raw TCP/UDP.")
o.write = function(self, section, value)
	if value ~= "socks" and value ~= "http" then value = "socks" end
	return ListValue.write(self, section, value)
end

o = s:option(Value, "username", translate("Username"))
o.rmempty = true

o = s:option(Value, "password", translate("Password"))
o.password = true
o.rmempty = true

api.type_cbi_section(s1, s)
