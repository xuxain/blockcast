Blockcast 节点操作指南  
支持基于 Ubuntu Linux + Docker 的系统。  
🔧 运行要求【最低 2 个 CPU 核心 + 4GB 内存】  
已安装 Docker 及 Docker Compose  
具备基础终端操作知识  
开放端口（若处于 NAT 网络环境后）  
注册流程  
创建账号：访问 [https://app.blockcast.network/](https://app.blockcast.network?referral-code=adLZO4)  
通过邮箱完成注册  
接收并填写邮箱验证码  
进入个人资料页面  
绑定钱包 > 关联 Twitter 和 Discord 账号  
注册完成  
## 运行步骤
```bash
wget https://raw.githubusercontent.com/xuxain/blockcast/refs/heads/main/blockcast.sh && chmod +x blockcast.sh && ./blockcast.sh
```
选择选项 1（安装）  
安装完成后等待一分钟运行
```bash
cd ~/.blockcast/compose
```
```bash
docker compose exec blockcastd blockcastd init
```
它将生成一个包含您的设备硬件ID、挑战密钥和注册URL的输出：


Hardware ID:
------------
c6ff0e6f-bc4d-4151-47c3-07df0e3cf53f

Challenge Key:
--------------
MCowBQYDK2VwAyEAXP49l4pBK1V5qy7vbRJYv3etRdEr7ycsQAvrgS+hQY0=

Register URL:
-------------
https://app.blockcast.network/register?hwid=c6ff0e6f-bc4d-4151-47c3-07df0e3cf53f&chall
确保挑战 ID（Challange ID）、硬件 ID（Hardware ID）与注册信息一致  
复制安装后给的网址到浏览器打开绑定或者复制Challange ID和Challenge KEY在网站手动绑定  
完成节点注册  
全部操作完成  
