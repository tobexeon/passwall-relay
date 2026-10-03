## :mega:公告
自 2026 年 6 月 1 日起，Xray Core 内部定时器已自动弃用 `allowInsecure`（跳过证书验证），并要求自签证书必须配置 `pinnedPeerCertSha256`（`pcs` 参数）。

若机场使用自签证书且未提供 `pcs` 参数，节点将无法正常连接。

**解决方法：**

* 向机场获取 `pinnedPeerCertSha256`（`pcs` 参数）；
* 或切换至 Sing-box Core。  

## 📌如何能编译到最新代码？

### 方法1：

执行 `./scripts/feeds update -a` 操作前，在 `feeds.conf.default` **顶部**插入如下代码：

```
src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main
src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main
```

### 方法2：

在 `./scripts/feeds install -a` 操作完成后，执行以下命令：

```shell
# 移除 openwrt feeds 自带的核心库
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages

# 移除 openwrt feeds 过时的luci版本
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci
```


## :satellite:新增功能：LAN 转发出口（内核态策略路由）

新增节点类型 **LAN Forward**：不启动任何本地代理客户端（sing-box / xray / ipt2socks 均不需要），
由 iptables/nftables 在内核态给代理流量打 fwmark，再经**策略路由**（`ip rule` + 独立路由表）
把流量**原封不动**路由到局域网内其他设备——**无 NAT、不改写目的地址/端口、全程内核态**。

典型场景：本机（路由器，如 10.10.10.1）配置一个 LAN Forward 节点，目标地址填高性能可翻墙设备
（如 10.10.10.10），该设备作为**下一跳网关**用透明代理（TPROXY/TUN）捕获流量。客户端访问
`google.com:443` 时，路由器不改写任何地址，只是把流量按策略路由丢给 10.10.10.10，
原始目的地址完整保留，目标设备可正常还原。

### 使用方法

1. 「节点列表」→「添加」→ 类型选择 **LAN Forward**；
2. 填写：目标设备地址（局域网 IP，下一跳网关）：如 `10.10.10.10`（**无需端口**；
   转发协议字段仅用户态兜底场景使用）；
3. 目标设备须开启 IP 转发并运行网关式透明代理（Clash TUN / sing-box TUN / TPROXY 等）；
4. 全局设置中把该节点设为全局节点（或用于访问控制/分流），TCP/UDP 代理流量即被内核态转发。

### 原理

- 全局节点为 LAN Forward 时，`start_global()` 不拉起任何代理进程，仅设置
  `LAN_FORWARD` / `LAN_FORWARD_ADDRESS` 供防火墙脚本读取；
- iptables 默认 ACL 对代理流量使用 `-j MARK --set-mark 0x50535732`（mangle 表 PSW 链），
  nftables 使用 `meta mark set 0x50535732`（PSW_MANGLE 链），替代原 TPROXY/REDIRECT；
- `lan_forward_route_add()` 添加 `ip rule fwmark 0x50535732 → table 1000`，
  表 1000 内 `default via <目标设备>`（区别于 TPROXY 的 fwmark 0x50535731 / table 999）；
- 开启时逐个接口关闭 `send_redirects`（`net.ipv4.conf.*/send_redirects=0`），
  防止内核向客户端发送 ICMP Redirect 通告导致客户端绕过路由器直连目标设备；停止时恢复原值；
- ICMP、IPv6 代理规则在 LAN 转发模式下自动跳过；
- 节点连通性测试退化为对目标设备 IP 的 ping 探测。

### 注意事项

- 目标设备必须是**网关式透明代理**（能捕获"目的地址非本机"的流量并还原原始目的），
  例如 Clash TUN、sing-box TUN、OpenWrt 旁路由 TPROXY 等；普通 Socks5 代理客户端不适用
  （它期待 Socks 握手，无法处理被原样转发的原始 TCP 流）；
- 仅支持 IPv4 目标地址；
- 目标设备需位于同一局域网并开启 `net.ipv4.ip_forward=1`；
- 本功能在 OpenWrt 真实环境生效（容器内无 uci/OpenWrt 防火墙，仅做语法与规则构造验证）。
