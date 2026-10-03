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


## :satellite:新增功能

**1. LAN 转发出口（内核态策略路由）**

新增节点类型 **LAN Forward**：不启动任何本地代理客户端，由 iptables/nftables 在内核态给代理流量打 fwmark，
经策略路由（`ip rule` + 独立路由表）把流量原样转发到局域网内其他翻墙设备（如 10.10.10.10），
无 NAT、不改写目的地址/端口，全程内核态。开启时自动逐接口关闭 `send_redirects`，防止内核发 ICMP Redirect 导致客户端绕过路由器。

用法：节点列表添加「LAN Forward」节点，填目标设备 IP（下一跳网关，无需端口），设为全局/分流节点即可；
目标设备需开启 IP 转发并运行网关式透明代理（Clash TUN / sing-box TUN / TPROXY 等）。

**2. ChinaDNS-NG 默认开启 DNS 缓存**

chinadns-ng 配置默认启用 `cache 4096 / cache-stale 86400 / cache-refresh 20`（配合原有 `verdict-cache 5000`），减少重复查询。