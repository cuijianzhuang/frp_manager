# FRP 服务器管理脚本

这是一个用于管理 FRP (Fast Reverse Proxy) 服务器的 Shell 脚本，提供了完整的安装、配置、管理和更新功能。

## 功能特性

- ✨ 自动安装最新版本 FRP
- 🔧 自动配置服务和基本设置
- 🚀 服务管理（启动/停止/重启）
- 📊 状态监控
- 🔄 自动更新
- 🔌 开机自启动管理
- 🗑️ 完全卸载功能
- 🌐 Web管理面板

## 系统要求

- Linux 操作系统
- systemd
- root 权限
- curl
- wget
- git
- Node.js (Web面板需要)

支持的架构：
- x86_64 (amd64)
- aarch64 (arm64)

## 快速开始

1. 下载脚本：
```bash
git clone https://github.com/cuijianzhuang/frp_manager.git
cd frp_manager
```

2. 添加执行权限：
```bash
chmod +x frp_manager.sh
```

3. 运行脚本：
```bash
sudo ./frp_manager.sh
```

## 功能菜单

1. 安装 FRP - 安装FRP服务器
2. 配置 FRP - 修改FRP配置文件
3. 启动 FRP - 启动FRP服务
4. 停止 FRP - 停止FRP服务
5. 重启 FRP - 重启FRP服务
6. 查看状态 - 查看FRP运行状态
7. 删除 FRP - 完全删除FRP
8. 设置开机自启动 - 设置FRP开机自动启动
9. 关闭开机自启动 - 关闭FRP开机自动启动
10. 检查FRP更新 - 检查FRP是否有新版本
11. 更新FRP - 更新FRP到最新版本
12. 安装Web管理面板 - 安装Web界面管理面板
13. 删除Web管理面板 - 删除Web管理面板

## Web管理面板

### 功能特点

- 📊 可视化配置界面
- 🔒 基本认证保护
- 📝 实时日志查看
- 🔄 配置文件自动备份
- ⚡ 即时配置生效
- 🔑 安全的密码管理

### 安装说明

1. 在主菜单中选择选项12安装Web管理面板
2. 安装完成后会显示以下信息：
   - 访问地址（服务器IP）
   - 管理员用户名
   - 随机生成的安全密码

### 访问方式

- 默认端口：3000
- 默认用户名：admin
- 密码：安装时随机生成（请妥善保存）

### 面板功能

1. FRP配置管理：
   - 修改绑定端口
   - 设置面板端口
   - 配置认证信息
   - 设置访问令牌

2. 服务管理：
   - 查看服务状态
   - 实时查看日志
   - 重启服务

3. 安全设置：
   - 修改管理员密码
   - 密码强度验证
   - 自动备份配置

## 配置说明

### FRP配置

默认配置文件位置：`/usr/local/frp/frps.ini`

默认配置内容：
```ini
[common]
bind_port = 7000
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = admin
token = 12345678
```

### Web面板配置

配置文件位置：`/usr/local/frp-panel/.env`
```env
ADMIN_USER=admin
ADMIN_PASSWORD=<随机生成>
PORT=3000
```

## 目录结构

- FRP安装目录：`/usr/local/frp`
- FRP服务文件：`/etc/systemd/system/frps.service`
- FRP配置文件：`/usr/local/frp/frps.ini`
- Web面板目录：`/usr/local/frp-panel`
- Web面板配置：`/usr/local/frp-panel/.env`
- Web面板服务：`/etc/systemd/system/frp-panel.service`

## 更新说明

### FRP更新
1. 自动检查最新版本
2. 备份现有配置
3. 下载并安装新版本
4. 恢复原有配置
5. 自动重启服务


## 安全建议

1. 首次安装后立即修改：
   - FRP面板密码
   - Web管理面板密码
   - 认证令牌

2. 访问安全：
   - 使用强密码
   - 定期更换密码
   - 限制访问IP
   - 建议使用反向代理并启用HTTPS

3. 配置备份：
   - 定期备份配置文件
   - 保存好随机生成的密码
   - 记录自定义的配置修改

## 故障排除

1. FRP服务问题：
   - 检查配置文件语法
   - 确认端口未被占用
   - 查看系统日志：`journalctl -u frps`

2. Web面板问题：
   - 检查Node.js安装
   - 确认3000端口可用
   - 查看面板日志：`journalctl -u frp-panel`

3. 更新失败：
   - 检查网络连接
   - 确认GitHub可访问
   - 查看错误日志

## 卸载说明

### 卸载FRP
```bash
# 使用脚本菜单选项7
# 或手动执行：
systemctl stop frps
systemctl disable frps
rm -f /etc/systemd/system/frps.service
rm -rf /usr/local/frp
```

### 卸载Web面板
```bash
# 使用脚本菜单选项15
# 或手动执行：
systemctl stop frp-panel
systemctl disable frp-panel
rm -f /etc/systemd/system/frp-panel.service
rm -rf /usr/local/frp-panel
```

## 版本历史

### v1.0.0
- 初始版本发布
- 基本功能实现
- Web管理面板支持

## 贡献指南

欢迎提交Issue和Pull Request！

1. Fork本仓库
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 许可证

MIT License

## 致谢

- [FRP 项目](https://github.com/fatedier/frp)
- [Express](https://expressjs.com/)
- [Node.js](https://nodejs.org/)


