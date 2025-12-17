#!/bin/bash

# 定义颜色常量（用于终端输出美化）
红='\033[0;31m'
绿='\033[0;32m'
黄='\033[1;33m'
蓝='\033[0;34m'
紫='\033[0;35m'
青='\033[0;36m'
无颜色='\033[0m' # 恢复默认颜色

# 项目配置常量
项目名称="Blockcast"
Docker组合目录="beacon-docker-compose"
仓库地址="https://github.com/Blockcast/beacon-docker-compose.git"

# 功能：显示项目LOGO
显示LOGO() {
    echo ""
    # 从仓库获取BangPateng的LOGO（失败则使用备用LOGO）
    curl -s https://raw.githubusercontent.com/bangpateng/logo/refs/heads/main/logo.sh | bash 2>/dev/null || {
        # 备用LOGO（Blockcast字符画）
        echo -e "${紫}"
        echo "██████╗  █████╗ ███╗   ██╗ ██████╗ ██████╗  █████╗ ████████╗███████╗███╗   ██╗ ██████╗ "
        echo "██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝████╗  ██║██╔════╝ "
        echo "██████╔╝███████║██╔██╗ ██║██║  ███╗██████╔╝███████║   ██║   █████╗  ██╔██╗ ██║██║  ███╗"
        echo "██╔══██╗██╔══██║██║╚██╗██║██║   ██║██╔═══╝ ██╔══██║   ██║   ██╔══╝  ██║╚██╗██║██║   ██║"
        echo "██████╔╝██║  ██║██║ ╚████║╚██████╔╝██║     ██║  ██║   ██║   ███████╗██║ ╚████║╚██████╔╝"
        echo "╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝ ╚═════╝ "
        echo -e "${无颜色}"
    }
    echo ""
    echo -e "${青}═══════════════════════════════════════════════════════════════════════════${无颜色}"
    echo -e "${绿}                    ⚡ BLOCKCAST Docker 自动安装脚本 ⚡                 ${无颜色}"
    echo -e "${蓝}                        🚀 脚本由 QQ群902879403 免费开发 🚀                       ${无颜色}"
    echo -e "${青}═══════════════════════════════════════════════════════════════════════════${无颜色}"
    echo ""
}

# 功能：打印普通信息
打印信息() {
    echo -e "${绿}[信息]${无颜色} $1"
}

# 功能：打印错误信息
打印错误() {
    echo -e "${红}[错误]${无颜色} $1"
}

# 功能：打印警告信息
打印警告() {
    echo -e "${黄}[警告]${无颜色} $1"
}

# 功能：打印步骤信息
打印步骤() {
    echo -e "${蓝}[步骤]${无颜色} $1"
}

# 功能：检查当前用户是否为root
检查根用户() {
    if [[ $EUID -eq 0 ]]; then
        打印警告 "当前以root用户运行，将自动使用管理员权限执行命令"
        管理员命令=""
    else
        管理员命令="sudo"
    fi
}

# 功能：检查Docker是否已安装并运行
检查Docker状态() {
    # 检查docker和docker-compose命令是否存在，且docker服务是否运行
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        if systemctl is-active --quiet docker; then
            return 0 # Docker已安装并运行
        fi
    fi
    return 1 # Docker未安装或未运行
}

# 功能：安装系统依赖包
安装系统依赖() {
    打印步骤 "正在更新系统软件包..."
    
    $管理员命令 apt update && $管理员命令 apt upgrade -y
    
    if [ $? -ne 0 ]; then
        打印错误 "系统软件包更新失败"
        exit 1
    fi
    
    打印步骤 "正在安装必需的依赖包..."
    
    $管理员命令 apt install ca-certificates curl gnupg lsb-release -y
    
    if [ $? -eq 0 ]; then
        打印信息 "依赖包安装成功"
    else
        打印错误 "依赖包安装失败"
        exit 1
    fi
}

# 功能：使用官方方法安装Docker
安装Docker() {
    打印步骤 "正在添加Docker的GPG密钥..."
    
    # 创建密钥环目录
    $管理员命令 mkdir -p /etc/apt/keyrings
    
    # 下载并添加Docker官方GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $管理员命令 gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    if [ $? -ne 0 ]; then
        打印错误 "Docker GPG密钥添加失败"
        exit 1
    fi
    
    打印步骤 "正在添加Docker软件源..."
    
    # 添加Docker官方软件源到系统
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      $管理员命令 tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    if [ $? -ne 0 ]; then
        打印错误 "Docker软件源添加失败"
        exit 1
    fi
    
    打印步骤 "正在更新软件包索引..."
    $管理员命令 apt update
    
    打印步骤 "正在安装Docker引擎..."
    $管理员命令 apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
    
    if [ $? -ne 0 ]; then
        打印错误 "Docker安装失败"
        exit 1
    fi
    
    打印步骤 "正在设置Docker服务开机自启并启动服务..."
    $管理员命令 systemctl enable docker
    $管理员命令 systemctl start docker
    
    if [ $? -eq 0 ]; then
        打印信息 "Docker服务启动成功"
    else
        打印错误 "Docker服务启动失败"
        exit 1
    fi
    
    # 非root用户添加到docker用户组（避免每次执行docker都需要sudo）
    if [[ $EUID -ne 0 ]]; then
        打印步骤 "正在将当前用户添加到docker用户组..."
        $管理员命令 usermod -aG docker $USER
        打印警告 "你需要注销并重新登录，才能无需sudo执行docker命令"
        打印警告 "或者执行 'newgrp docker' 命令立即应用用户组更改"
    fi
    
    打印步骤 "正在验证Docker安装是否成功..."
    docker --version
    docker compose version
    
    if [ $? -eq 0 ]; then
        打印信息 "Docker安装并验证成功"
    else
        打印错误 "Docker验证失败"
        exit 1
    fi
}

# 功能：克隆项目仓库并初始化配置
配置项目() {
    打印步骤 "正在克隆Blockcast项目仓库..."
    
    # 如果项目目录已存在，先删除
    if [ -d "$Docker组合目录" ]; then
        打印警告 "目录 $Docker组合目录 已存在，正在删除..."
        rm -rf "$Docker组合目录"
    fi
    
    # 克隆仓库
    git clone "$仓库地址"
    
    if [ $? -eq 0 ]; then
        打印信息 "项目仓库克隆成功"
    else
        打印错误 "项目仓库克隆失败"
        exit 1
    fi
    
    # 进入项目目录
    cd "$Docker组合目录" || {
        打印错误 "进入项目目录失败"
        exit 1
    }
    
    打印步骤 "正在拉取Docker镜像..."
    docker compose pull
    
    if [ $? -eq 0 ]; then
        打印信息 "Docker镜像拉取成功"
    else
        打印错误 "Docker镜像拉取失败"
        exit 1
    fi
}

# 功能：启动Blockcast服务
启动服务() {
    打印步骤 "正在启动Blockcast Docker服务..."
    
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        打印信息 "Docker服务启动成功"
    else
        打印错误 "Docker服务启动失败"
        exit 1
    fi
    
    # 等待服务初始化
    打印步骤 "正在等待服务初始化（15秒）..."
    sleep 15
    
    打印步骤 "正在初始化blockcastd服务..."
    docker compose exec blockcastd blockcastd init
    
    if [ $? -eq 0 ]; then
        打印信息 "blockcastd初始化成功"
    else
        打印警告 "blockcastd初始化可能失败 - 请检查日志"
    fi
}

# 功能：安装Blockcast完整流程
安装Blockcast() {
    显示LOGO
    
    打印信息 "开始安装 $项目名称 ..."
    
    检查根用户
    
    # 检查Docker是否已安装并运行
    if 检查Docker状态; then
        打印信息 "Docker已安装并正在运行"
        docker --version
        docker compose version
    else
        打印步骤 "未找到Docker或Docker未运行，正在安装..."
        安装系统依赖
        安装Docker
        
        # 非root用户需要重新登录，因此退出脚本提示用户重新运行
        if [[ $EUID -ne 0 ]]; then
            打印警告 "Docker已安装完成，请注销并重新登录后，再次运行此脚本"
            打印警告 "或者执行 'newgrp docker' 命令后，再次运行此脚本"
            exit 0
        fi
    fi
    
    配置项目
    启动服务
    
    echo ""
    echo -e "${绿}════════════════════════════════════════════════════════════════════════════════════${无颜色}"
    echo -e "${绿}                           安装成功！                                 ${无颜色}"
    echo -e "${绿}════════════════════════════════════════════════════════════════════════════════════${无颜色}"
    echo ""
    打印信息 "Blockcast Docker已成功安装并启动！"
    echo ""
    echo -e "${青}常用命令：${无颜色}"
    echo -e "  ${黄}cd $Docker组合目录${无颜色}         - 进入项目目录"
    echo -e "  ${黄}docker compose logs -f${无颜色}        - 查看服务实时日志"
    echo -e "  ${黄}docker compose ps${无颜色}             - 查看容器状态"
    echo -e "  ${黄}docker compose stop${无颜色}           - 停止服务"
    echo -e "  ${黄}docker compose start${无颜色}          - 启动服务"
    echo -e "  ${黄}docker compose restart${无颜色}        - 重启服务"
    echo ""
    echo -e "${蓝}项目位置：${无颜色} $(pwd)"
    echo ""
}

# 功能：卸载Blockcast
卸载Blockcast() {
    显示LOGO
    
    打印警告 "开始卸载 $项目名称 ..."
    echo ""
    
    # 检查项目目录是否存在
    if [ ! -d "$Docker组合目录" ]; then
        打印错误 "目录 $Docker组合目录 未找到！"
        打印信息 "正在搜索运行中的Blockcast容器..."
        
        # 查找所有Blockcast相关容器
        Blockcast容器=$(docker ps -a --filter "name=blockcast" --format "{{.Names}}" 2>/dev/null)
        
        if [ -n "$Blockcast容器" ]; then
            打印警告 "找到以下Blockcast容器："
            echo "$Blockcast容器"
            echo ""
            read -p "是否要删除这些容器？(y/N)：" -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "$Blockcast容器" | xargs docker rm -f
                打印信息 "Blockcast容器删除成功"
            fi
        else
            打印信息 "未找到Blockcast容器"
        fi
        return
    fi
    
    # 进入项目目录
    cd "$Docker组合目录" || {
        打印错误 "进入目录 $Docker组合目录 失败"
        exit 1
    }
    
    打印步骤 "正在停止并删除Docker容器..."
    
    # 停止并删除容器（包括卷和孤立容器）
    docker compose down --volumes --remove-orphans
    
    if [ $? -eq 0 ]; then
        打印信息 "Docker容器停止并删除成功"
    else
        打印警告 "停止容器时出现问题，继续执行卸载流程..."
    fi
    
    # 删除项目相关的Docker镜像
    打印步骤 "正在删除项目相关的Docker镜像..."
    
    镜像列表=$(docker compose config --images 2>/dev/null)
    if [ -n "$镜像列表" ]; then
        echo "$镜像列表" | xargs docker rmi -f 2>/dev/null || true
        打印信息 "项目Docker镜像删除成功"
    fi
    
    # 返回上级目录
    cd ..
    
    # 删除项目目录
    打印步骤 "正在删除项目目录..."
    rm -rf "$Docker组合目录"
    
    if [ $? -eq 0 ]; then
        打印信息 "项目目录删除成功"
    else
        打印错误 "项目目录删除失败"
    fi
    
    # 清理未使用的Docker资源（仅孤立资源）
    打印步骤 "正在清理未使用的Docker资源..."
    docker system prune -f --volumes 2>/dev/null || true
    
    echo ""
    echo -e "${绿}════════════════════════════════════════════════════════════════════════════════════${无颜色}"
    echo -e "${绿}                          卸载成功！                               ${无颜色}"
    echo -e "${绿}════════════════════════════════════════════════════════════════════════════════════${无颜色}"
    echo ""
    打印信息 "Blockcast Docker已成功卸载！"
    打印信息 "Docker和其他容器不受影响，保持原样。"
    echo ""
}

# 功能：查看Blockcast状态
查看状态() {
    显示LOGO
    
    打印信息 "$项目名称 Docker 状态信息："
    echo ""
    
    if [ -d "$Docker组合目录" ]; then
        cd "$Docker组合目录" || exit 1
        
        打印步骤 "容器状态："
        docker compose ps
        
        echo ""
        打印步骤 "最近日志（最后30行）："
        docker compose logs --tail=30
        
        echo ""
        打印步骤 "系统资源使用情况："
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    else
        打印警告 "项目未安装或目录未找到"
        echo ""
        打印步骤 "正在检查运行中的Blockcast容器..."
        docker ps --filter "name=blockcast" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
}

# 功能：重启Blockcast服务
重启服务() {
    显示LOGO
    
    打印步骤 "正在重启 $项目名称 服务..."
    
    if [ ! -d "$Docker组合目录" ]; then
        打印错误 "项目目录未找到！"
        exit 1
    fi
    
    cd "$Docker组合目录" || exit 1
    
    docker compose restart
    
    if [ $? -eq 0 ]; then
        打印信息 "服务重启成功"
        echo ""
        打印步骤 "当前服务状态："
        docker compose ps
    else
        打印错误 "服务重启失败"
    fi
}

# 功能：显示主菜单
显示菜单() {
    显示LOGO
    
    echo -e "${青}请选择操作选项：${无颜色}"
    echo -e "  ${绿}1)${无颜色} 安装 Blockcast Docker"
    echo -e "  ${黄}2)${无颜色} 卸载 Blockcast Docker"
    echo -e "  ${蓝}3)${无颜色} 查看服务状态"
    echo -e "  ${紫}4)${无颜色} 重启服务"
    echo -e "  ${红}5)${无颜色} 退出脚本"
    echo ""
    
    read -p "请输入你的选择（1-5）：" 选择项
    
    case $选择项 in
        1)
            安装Blockcast
            ;;
        2)
            echo ""
            read -p "确定要卸载Blockcast Docker吗？(y/N)：" -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                卸载Blockcast
            else
                打印信息 "卸载操作已取消"
            fi
            ;;
        3)
            查看状态
            ;;
        4)
            重启服务
            ;;
        5)
            打印信息 "感谢使用Blockcast安装脚本！"
            exit 0
            ;;
        *)
            打印错误 "少侠,你选错了！"
            显示菜单
            ;;
    esac
}

# 主程序入口：判断脚本运行参数
if [ $# -eq 0 ]; then
    # 无参数时显示菜单
    显示菜单
else
    # 有参数时执行对应操作
    case $1 in
        install)
            安装Blockcast
            ;;
        uninstall)
            echo ""
            read -p "确定要卸载Blockcast Docker吗？(y/N)：" -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                卸载Blockcast
            else
                打印信息 "卸载操作已取消"
            fi
            ;;
        status)
            查看状态
            ;;
        restart)
            重启服务
            ;;
        *)
            echo "使用方法：$0 [install|uninstall|status|restart]"
            exit 1
            ;;
    esac
fi
