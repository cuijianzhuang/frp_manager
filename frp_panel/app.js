const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const ini = require('ini');
const { exec } = require('child_process');
const path = require('path');
const basicAuth = require('express-basic-auth');
const crypto = require('crypto');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;
const ENV_FILE = '.env';

// 基本认证中间件
const auth = basicAuth({
    users: { [process.env.ADMIN_USER || 'admin']: process.env.ADMIN_PASSWORD || 'admin' },
    challenge: true,
    realm: 'FRP Management Panel'
});

// 更新环境变量文件
function updateEnvFile(newPassword) {
    try {
        const envPath = path.join(__dirname, ENV_FILE);
        let envContent = fs.readFileSync(envPath, 'utf8');
        
        // 更新密码
        envContent = envContent.replace(
            /ADMIN_PASSWORD=.*/,
            `ADMIN_PASSWORD=${newPassword}`
        );
        
        fs.writeFileSync(envPath, envContent);
        return true;
    } catch (error) {
        console.error('更新环境变量文件失败:', error);
        return false;
    }
}

app.use(bodyParser.json());
app.use(auth); // 添加认证中间件
app.use(express.static('public'));

// 记录访问日志
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - ${req.ip}`);
    next();
});

// 错误处理中间件
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: '服务器内部错误' });
});

// 修改管理员密码
app.post('/api/admin/password', (req, res) => {
    const { password } = req.body;
    
    if (!password || password.length < 6) {
        return res.status(400).json({ 
            success: false, 
            error: '密码长度必须至少为6个字符' 
        });
    }
    
    try {
        // 更新环境变量文件
        if (!updateEnvFile(password)) {
            throw new Error('更新密码失败');
        }
        
        // 重新加载环境变量
        require('dotenv').config();

        // 先发送响应
        res.json({ 
            success: true, 
            message: '密码已更新，服务即将重启' 
        });

        // 延迟1秒后重启，确保响应已发送
        setTimeout(() => {
            process.on('exit', () => {
                require('child_process').spawn(process.argv[0], process.argv.slice(1), {
                    detached: true,
                    stdio: ['ignore', 'ignore', 'ignore']
                }).unref();
            });
            process.exit();
        }, 1000);
        
    } catch (error) {
        res.status(500).json({ 
            success: false, 
            error: '更新密码失败' 
        });
    }
});

// 配置文件路径
const CONFIG_PATH = '/usr/local/frp/frps.ini';

// 获取FRP配置
app.get('/api/config', (req, res) => {
    try {
        const config = ini.parse(fs.readFileSync(CONFIG_PATH, 'utf-8'));
        res.json(config);
    } catch (error) {
        res.status(500).json({ error: '读取配置失败' });
    }
});

// 更新FRP配置
app.post('/api/config', (req, res) => {
    try {
        const config = req.body;
        // 配置文件备份
        const backupPath = `${CONFIG_PATH}.backup-${Date.now()}`;
        fs.copyFileSync(CONFIG_PATH, backupPath);
        
        fs.writeFileSync(CONFIG_PATH, ini.stringify(config));
        
        // 重启FRP服务
        exec('systemctl restart frps', (error) => {
            if (error) {
                // 如果重启失败，恢复备份
                fs.copyFileSync(backupPath, CONFIG_PATH);
                res.status(500).json({ error: '重启服务失败，已恢复配置' });
                return;
            }
            res.json({ message: '配置已更新并重启服务' });
        });
    } catch (error) {
        res.status(500).json({ error: '更新配置失败' });
    }
});

// 获取FRP状态
app.get('/api/status', (req, res) => {
    exec('systemctl status frps', (error, stdout) => {
        if (error) {
            res.status(500).json({ error: '获取状态失败' });
            return;
        }
        res.json({ status: stdout });
    });
});

// 获取最近的日志
app.get('/api/logs', (req, res) => {
    exec('journalctl -u frps -n 50 --no-pager', (error, stdout) => {
        if (error) {
            res.status(500).json({ error: '获取日志失败' });
            return;
        }
        res.json({ logs: stdout });
    });
});

// 获取原始配置文件内容
app.get('/api/config/raw', (req, res) => {
    try {
        const configContent = fs.readFileSync(CONFIG_PATH, 'utf-8');
        res.json({ content: configContent });
    } catch (error) {
        res.status(500).json({ error: '读取配置失败' });
    }
});

// 保存原始配置文件内容
app.post('/api/config/raw', (req, res) => {
    try {
        const { content } = req.body;
        
        // 配置文件备份
        const backupPath = `${CONFIG_PATH}.backup-${Date.now()}`;
        fs.copyFileSync(CONFIG_PATH, backupPath);
        
        // 写入新配置
        fs.writeFileSync(CONFIG_PATH, content);
        
        // 重启FRP服务
        exec('systemctl restart frps', (error) => {
            if (error) {
                // 如果重启失败，恢复备份
                fs.copyFileSync(backupPath, CONFIG_PATH);
                res.status(500).json({ error: '重启服务失败，已恢复配置' });
                return;
            }
            res.json({ message: '配置已更新并重启服务' });
        });
    } catch (error) {
        res.status(500).json({ error: '更新配置失败' });
    }
});

app.listen(port, () => {
    console.log(`FRP管理面板运行在 http://localhost:${port}`);
}); 