// 加载配置
async function loadConfig() {
    try {
        const response = await fetch('/api/config');
        const config = await response.json();
        
        document.getElementById('bindPort').value = config.common.bind_port;
        document.getElementById('dashboardPort').value = config.common.dashboard_port;
        document.getElementById('dashboardUser').value = config.common.dashboard_user;
        document.getElementById('dashboardPwd').value = config.common.dashboard_pwd;
        document.getElementById('token').value = config.common.token;
    } catch (error) {
        alert('加载配置失败');
    }
}

// 保存配置
async function saveConfig(event) {
    event.preventDefault();
    
    const config = {
        common: {
            bind_port: document.getElementById('bindPort').value,
            dashboard_port: document.getElementById('dashboardPort').value,
            dashboard_user: document.getElementById('dashboardUser').value,
            dashboard_pwd: document.getElementById('dashboardPwd').value,
            token: document.getElementById('token').value
        }
    };

    try {
        const response = await fetch('/api/config', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(config)
        });
        
        const result = await response.json();
        alert(result.message || '保存成功');
    } catch (error) {
        alert('保存配置失败');
    }
}

// 刷新状态
async function refreshStatus() {
    try {
        const response = await fetch('/api/status');
        const data = await response.json();
        document.getElementById('status').textContent = data.status;
    } catch (error) {
        alert('获取状态失败');
    }
}

// 加载原始配置文件内容
async function loadRawConfig() {
    try {
        const response = await fetch('/api/config/raw');
        const data = await response.json();
        document.getElementById('configEditor').value = data.content;
    } catch (error) {
        alert('加载配置失败');
    }
}

// 保存原始配置文件内容
async function saveRawConfig() {
    const content = document.getElementById('configEditor').value;
    
    if (!confirm('确定要保存更改并重启服务吗？')) {
        return;
    }
    
    try {
        const response = await fetch('/api/config/raw', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ content })
        });
        
        const result = await response.json();
        if (response.ok) {
            alert(result.message || '保存成功');
            // 重新加载配置到表单
            loadConfig();
        } else {
            alert(result.error || '保存失败');
        }
    } catch (error) {
        alert('保存配置失败');
    }
}

// 初始化图表
let trafficChart;
function initTrafficChart() {
    const ctx = document.getElementById('trafficChart').getContext('2d');
    trafficChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: Array(30).fill(''),
            datasets: [{
                label: '入站流量',
                data: Array(30).fill(0),
                borderColor: '#2196F3',
                tension: 0.4,
                fill: false
            }, {
                label: '出站流量',
                data: Array(30).fill(0),
                borderColor: '#4CAF50',
                tension: 0.4,
                fill: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: '流量 (KB/s)'
                    }
                }
            }
        }
    });
}

// 更新监控数据
async function updateMonitoring() {
    try {
        const response = await fetch('/api/monitoring');
        const data = await response.json();
        
        // 更新指标卡片
        document.getElementById('cpuUsage').textContent = `${data.cpu}%`;
        document.getElementById('memoryUsage').textContent = `${data.memory}%`;
        document.getElementById('connections').textContent = data.connections;
        document.getElementById('networkTraffic').textContent = `${data.currentTraffic} KB/s`;
        
        // 更新图表
        trafficChart.data.datasets[0].data.shift();
        trafficChart.data.datasets[0].data.push(data.inbound);
        trafficChart.data.datasets[1].data.shift();
        trafficChart.data.datasets[1].data.push(data.outbound);
        trafficChart.update();
    } catch (error) {
        console.error('获取监控数据失败:', error);
    }
}

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    loadConfig();
    refreshStatus();
    document.getElementById('configForm').addEventListener('submit', saveConfig);

    // 添加密码修改表单监听
    document.getElementById('adminForm').addEventListener('submit', async (event) => {
        event.preventDefault();
        
        const newPassword = document.getElementById('newPassword').value;
        const confirmPassword = document.getElementById('confirmPassword').value;
        
        if (newPassword !== confirmPassword) {
            alert('两次输入的密码不一致');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/password', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ password: newPassword })
            });
            
            const result = await response.json();
            if (result.success) {
                alert('密码修改成功！系统将在3秒后重启，请稍后使用新密码重新登录。');
                // 清空表单
                event.target.reset();
                // 等待3秒后刷新页面
                setTimeout(() => {
                    window.location.reload();
                }, 3000);
            } else {
                alert(result.error || '密码修改失败');
            }
        } catch (error) {
            alert('密码修改失败，请稍后重试');
        }
    });

    // 加载原始配置
    loadRawConfig();

    // 初始化监控图表
    initTrafficChart();
    
    // 定期更新监控数据
    updateMonitoring();
    setInterval(updateMonitoring, 2000);
}); 