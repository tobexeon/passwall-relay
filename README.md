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


## :satellite:新增功能：LAN 转发出口（内核态 DNAT）

新增节点类型 **LAN Forward**：不启动任何本地代理客户端（sing-box / xray / ipt2socks 均不需要），
由 iptables/nftables 在内核态把代理流量 **DNAT** 转发到局域网内其他设备上运行的代理服务。

典型场景：本机（路由器，如 10.10.10.1）配置一个 LAN Forward 节点，目标地址填高性能可翻墙设备
（如 10.10.10.10）及其透明代理端口，所有被代理的 TCP/UDP 流量直接以内核态转发到该设备，全程不经过用户态。

### 使用方法

1. 「节点列表」→「添加」→ 类型选择 **LAN Forward**；
2. 填写：
   - 目标设备地址（局域网 IP）：如 `10.10.10.10`
   - 目标设备端口：目标设备上透明代理/代理客户端监听端口（如 `7890`）
   - 转发协议：仅用户态场景（分流/ACL 单节点）使用，内核转发路径忽略
3. 全局设置中把该节点设为全局节点（或用于访问控制/分流），TCP/UDP 代理流量即被内核态 DNAT 转发。

### 原理

- 全局节点为 LAN Forward 时，`start_global()` 不拉起任何代理进程，仅设置
  `LAN_FORWARD` / `LAN_FORWARD_ADDRESS` / `LAN_FORWARD_PORT` 供防火墙脚本读取；
- iptables 默认 ACL 使用 `-j DNAT --to-destination <地址>:<端口>`（nat 表），
  nftables 使用 `ip dnat to <地址>:<端口>`，替代原 TPROXY/REDIRECT；
- ICMP、IPv6 代理规则在 LAN 转发模式下自动跳过；
- 节点连通性测试退化为对目标设备:端口的 TCP 连通性探测。

### 注意事项

- 目标设备必须能透明处理被转发过来的流量（能还原原始目的地址），例如运行 Clash TUN、
  sing-box TUN、ipt2socks 等透明代理方案；
- 仅支持 IPv4 目标地址；
- 内核态 DNAT 只能重定向目的地址/端口，无法伪装源地址，目标设备需位于同一局域网；
- 本功能在 OpenWrt 真实环境生效（容器内无 uci/OpenWrt 防火墙，仅做语法与规则构造验证）。
