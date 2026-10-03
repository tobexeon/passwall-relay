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
o.description = translate("The LAN IP of the next-hop gateway that actually does the proxying (e.g. 10.10.10.10). The kernel (iptables/nftables) marks the proxied traffic and policy-routes it to this device through a dedicated routing table -- no NAT, no port rewriting, the original destination is fully preserved. The target device must run a gateway-style transparent proxy (TPROXY/TUN) to capture and restore the original destination. No local proxy client is started on this router.")

api.type_cbi_section(s1, s)
