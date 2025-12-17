#!/bin/bash

# 检查Bash版本
if ((BASH_VERSINFO[0] < 4)); then
    echo "错误：需要Bash 4.0或更高版本"
    exit 1
fi

# 项目配置常量
PROJECT_NAME="Blockcast"
DOCKER_COMPOSE_DIR="beacon-docker-compose"
REPO_URL="https://github.com/Blockcast/beacon-docker-compose.git"

# 系统检测
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "[错误] 此脚本仅支持Linux系统"
    exit 1
fi

# 功能：显示项目LOGO
show_logo() {
    echo ""
        echo ""
        echo "██████╗  █████╗ ███╗   ██╗ ██████╗ ██████╗  █████╗ ████████╗███████╗███╗   ██╗ ██████╗ "
        echo "██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝████╗  ██║██╔════╝ "
        echo "██████╔╝███████║██╔██╗ ██║██║  ███╗██████╔╝███████║   ██║   █████╗  ██╔██╗ ██║██║  ███╗"
        echo "██╔══██╗██╔══██║██║╚██╗██║██║   ██║██╔═══╝ ██╔══██║   ██║   ██╔══╝  ██║╚██╗██║██║   ██║"
        echo "██████╔╝██║  ██║██║ ╚████║╚██████╔╝██║     ██║  ██║   ██║   ███████╗██║ ╚████║╚██████╔╝"
        echo "╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝ ╚═════╝ "
        echo ""
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "                    ⚡ BLOCKCAST Docker 自动安装脚本 ⚡                 "
    echo "                    🚀 脚本由 QQ群902879403 免费开发 🚀                       "
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""
}

# 功能：打印普通信息
print_info() {
    echo "[信息] $1"
}

# 功能：打印错误信息
print_error() {
    echo "[错误] $1"
}

# 功能：打印警告信息
print_warning() {
    echo "[警告] $1"
}

# 功能：打印步骤信息
print_step() {
    echo "[步骤] $1"
}

# 功能：检查当前用户是否为root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "当前以root用户运行，将自动使用管理员权限执行命令"
        ADMIN_CMD=""
    else
        ADMIN_CMD="sudo"
        print_info "当前为非root用户，将使用sudo执行需要权限的命令"
    fi
}

# 功能：检查Docker是否已安装并运行
check_docker_status() {
    # 检查docker命令是否存在
    if ! command -v docker &> /dev/null; then
        return 1
    fi
    
    # 检查docker-compose命令是否存在（支持新老版本）
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        return 1
    fi
    
    # 检查docker服务是否运行
    if systemctl is-active --quiet docker 2>/dev/null || pgrep -f "dockerd" > /dev/null; then
        return 0
    fi
    
    return 1
}

# 功能：安装系统依赖包
install_system_deps() {
    print_step "正在更新系统软件包..."
    
    $ADMIN_CMD apt update && $ADMIN_CMD apt upgrade -y
    
    if [ $? -ne 0 ]; then
        print_error "系统软件包更新失败"
        exit 1
    fi
    
    print_step "正在安装必需的依赖包..."
    
    $ADMIN_CMD apt install ca-certificates curl gnupg lsb-release software-properties-common -y
    
    if [ $? -eq 0 ]; then
        print_info "依赖包安装成功"
    else
        print_error "依赖包安装失败"
        exit 1
    fi
}

# 功能：使用官方方法安装Docker
install_docker() {
    print_step "正在添加Docker的GPG密钥..."
    
    # 创建密钥环目录
    $ADMIN_CMD mkdir -p /etc/apt/keyrings
    
    # 下载并添加Docker官方GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $ADMIN_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    if [ $? -ne 0 ]; then
        print_error "Docker GPG密钥添加失败"
        exit 1
    fi
    
    print_step "正在设置密钥权限..."
    $ADMIN_CMD chmod a+r /etc/apt/keyrings/docker.gpg
    
    print_step "正在添加Docker软件源..."
    
    # 添加Docker官方软件源到系统
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      $ADMIN_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    if [ $? -ne 0 ]; then
        print_error "Docker软件源添加失败"
        exit 1
    fi
    
    print_step "正在更新软件包索引..."
    $ADMIN_CMD apt update
    
    print_step "正在安装Docker引擎..."
    $ADMIN_CMD apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    
    if [ $? -ne 0 ]; then
        print_error "Docker安装失败"
        exit 1
    fi
    
    print_step "正在设置Docker服务开机自启并启动服务..."
    $ADMIN_CMD systemctl enable docker
    $ADMIN_CMD systemctl start docker
    
    if [ $? -eq 0 ]; then
        print_info "Docker服务启动成功"
    else
        print_error "Docker服务启动失败"
        exit 1
    fi
    
    # 非root用户添加到docker用户组
    if [[ $EUID -ne 0 ]]; then
        print_step "正在将当前用户添加到docker用户组..."
        $ADMIN_CMD usermod -aG docker $USER
        
        print_warning "用户组更改需要重新登录才能生效"
        print_info "当前会话将继续使用sudo执行docker命令"
        
        # 尝试设置当前会话的docker组（可选）
        if groups $USER | grep -q '\bdocker\b'; then
            print_info "当前用户已在docker组中"
        else
            print_warning "需要新会话才能应用docker组权限"
        fi
    fi
    
    print_step "正在验证Docker安装是否成功..."
    docker --version
    
    # 检查docker compose版本（兼容新老版本）
    if docker compose version &> /dev/null; then
        docker compose version
        print_info "使用Docker Compose V2"
    elif command -v docker-compose &> /dev/null; then
        docker-compose --version
        print_info "使用docker-compose独立版本"
    else
        print_error "未找到docker-compose命令"
        exit 1
    fi
    
    if [ $? -eq 0 ]; then
        print_info "Docker安装并验证成功"
    else
        print_error "Docker验证失败"
        exit 1
    fi
}

# 功能：克隆项目仓库并初始化配置
configure_project() {
    print_step "正在克隆Blockcast项目仓库..."
    
    # 如果项目目录已存在，询问用户
    if [ -d "$DOCKER_COMPOSE_DIR" ]; then
        print_warning "目录 $DOCKER_COMPOSE_DIR 已存在"
        read -p "是否删除并重新克隆？(y/N)：" -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "正在删除旧目录..."
            rm -rf "$DOCKER_COMPOSE_DIR"
        else
            print_info "使用现有目录..."
            cd "$DOCKER_COMPOSE_DIR" || {
                print_error "进入项目目录失败"
                exit 1
            }
            return
        fi
    fi
    
    # 克隆仓库
    git clone "$REPO_URL"
    
    if [ $? -eq 0 ]; then
        print_info "项目仓库克隆成功"
    else
        print_error "项目仓库克隆失败"
        print_info "请检查网络连接或Git是否安装"
        exit 1
    fi
    
    # 进入项目目录
    cd "$DOCKER_COMPOSE_DIR" || {
        print_error "进入项目目录失败"
        exit 1
    }
    
    print_step "正在检查Docker Compose文件..."
    if [ ! -f "docker-compose.yml" ] && [ ! -f "docker-compose.yaml" ]; then
        print_error "未找到docker-compose.yml文件"
        exit 1
    fi
    
    print_step "正在拉取Docker镜像..."
    # 兼容docker compose的不同版本
    if docker compose version &> /dev/null; then
        docker compose pull
    else
        docker-compose pull
    fi
    
    if [ $? -eq 0 ]; then
        print_info "Docker镜像拉取成功"
    else
        print_warning "Docker镜像拉取失败或部分失败"
        print_info "将继续尝试启动服务..."
    fi
}

# 功能：启动Blockcast服务
start_service() {
    print_step "正在启动Blockcast Docker服务..."
    
    # 兼容docker compose的不同版本
    if docker compose version &> /dev/null; then
        docker compose up -d
    else
        docker-compose up -d
    fi
    
    if [ $? -eq 0 ]; then
        print_info "Docker服务启动成功"
    else
        print_error "Docker服务启动失败"
        exit 1
    fi
    
    # 等待服务初始化
    print_step "正在等待服务初始化（15秒）..."
    for i in {1..15}; do
        echo -n "."
        sleep 1
    done
    echo ""
    
    # 尝试初始化blockcastd服务
    print_step "正在尝试初始化blockcastd服务..."
    if docker compose version &> /dev/null; then
        docker compose exec blockcastd blockcastd init 2>/dev/null || true
    else
        docker-compose exec blockcastd blockcastd init 2>/dev/null || true
    fi
    
    if [ $? -eq 0 ]; then
        print_info "blockcastd初始化完成"
    else
        print_warning "blockcastd初始化可能失败或不需要 - 请检查日志"
    fi
}

# 功能：安装Blockcast完整流程
install_blockcast() {
    show_logo
    
    print_info "开始安装 $PROJECT_NAME ..."
    
    check_root
    
    # 检查Docker是否已安装并运行
    if check_docker_status; then
        print_info "Docker已安装并正在运行"
        docker --version
        
        if docker compose version &> /dev/null; then
            docker compose version
        else
            docker-compose --version
        fi
    else
        print_step "未找到Docker或Docker未运行，正在安装..."
        install_system_deps
        install_docker
        
        # 重新检查Docker状态
        if ! check_docker_status; then
            print_error "Docker安装后仍无法正常运行"
            exit 1
        fi
    fi
    
    configure_project
    start_service
    
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════════"
    echo "                                  安装成功！                                 "
    echo "════════════════════════════════════════════════════════════════════════════════════"
    echo ""
    print_info "Blockcast Docker已成功安装并启动！"
    echo ""
    echo "常用命令："
    echo "  cd $DOCKER_COMPOSE_DIR         - 进入项目目录"
    
    # 根据docker compose版本显示不同命令
    if docker compose version &> /dev/null; then
        echo "  docker compose logs -f        - 查看服务实时日志"
        echo "  docker compose ps             - 查看容器状态"
        echo "  docker compose stop           - 停止服务"
        echo "  docker compose start          - 启动服务"
        echo "  docker compose restart        - 重启服务"
    else
        echo "  docker-compose logs -f        - 查看服务实时日志"
        echo "  docker-compose ps             - 查看容器状态"
        echo "  docker-compose stop           - 停止服务"
        echo "  docker-compose start          - 启动服务"
        echo "  docker-compose restart        - 重启服务"
    fi
    
    echo "  docker ps                     - 查看所有运行中的容器"
    echo "  docker stats                  - 查看容器资源使用情况"
    echo ""
    echo "项目位置： $(pwd)"
    echo ""
    
    # 显示容器状态
    print_step "当前服务状态："
    if docker compose version &> /dev/null; then
        docker compose ps
    else
        docker-compose ps
    fi
}

# 功能：卸载Blockcast
uninstall_blockcast() {
    show_logo
    
    print_warning "开始卸载 $PROJECT_NAME ..."
    echo ""
    
    # 检查项目目录是否存在
    if [ ! -d "$DOCKER_COMPOSE_DIR" ]; then
        print_warning "目录 $DOCKER_COMPOSE_DIR 未找到！"
        print_info "正在搜索运行中的Blockcast容器..."
        
        # 查找所有Blockcast相关容器
        BLOCKCAST_CONTAINERS=$(docker ps -a --filter "name=blockcast" --format "{{.Names}}" 2>/dev/null)
        
        if [ -n "$BLOCKCAST_CONTAINERS" ]; then
            print_warning "找到以下Blockcast容器："
            echo "$BLOCKCAST_CONTAINERS"
            echo ""
            read -p "是否要删除这些容器？(y/N)：" -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "$BLOCKCAST_CONTAINERS" | xargs -r docker rm -f
                print_info "Blockcast容器删除成功"
            else
                print_info "跳过容器删除"
            fi
        else
            print_info "未找到Blockcast容器"
        fi
        
        # 清理镜像
        read -p "是否要删除Blockcast相关镜像？(y/N)：" -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_step "正在删除Blockcast相关镜像..."
            docker images --filter "reference=*blockcast*" --format "{{.Repository}}:{{.Tag}}" | xargs -r docker rmi -f 2>/dev/null || true
            print_info "镜像清理完成"
        fi
        
        return
    fi
    
    # 进入项目目录
    cd "$DOCKER_COMPOSE_DIR" 2>/dev/null || {
        print_error "进入目录 $DOCKER_COMPOSE_DIR 失败"
        exit 1
    }
    
    print_step "正在停止并删除Docker容器..."
    
    # 停止并删除容器（兼容不同版本）
    if docker compose version &> /dev/null; then
        docker compose down --volumes --remove-orphans
    else
        docker-compose down --volumes --remove-orphans
    fi
    
    if [ $? -eq 0 ]; then
        print_info "Docker容器停止并删除成功"
    else
        print_warning "停止容器时出现问题，继续执行卸载流程..."
    fi
    
    # 返回上级目录
    cd ..
    
    # 删除项目目录
    print_step "正在删除项目目录..."
    if [ -d "$DOCKER_COMPOSE_DIR" ]; then
        rm -rf "$DOCKER_COMPOSE_DIR"
        if [ $? -eq 0 ]; then
            print_info "项目目录删除成功"
        else
            print_error "项目目录删除失败，请手动删除"
        fi
    fi
    
    # 清理未使用的Docker资源
    print_step "是否清理未使用的Docker资源？"
    read -p "这将删除未使用的镜像、容器、网络和卷 (y/N)：" -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker system prune -af --volumes
        print_info "Docker资源清理完成"
    else
        print_info "跳过Docker资源清理"
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════════"
    echo "                                  卸载成功！                               "
    echo "════════════════════════════════════════════════════════════════════════════════════"
    echo ""
    print_info "Blockcast Docker已成功卸载！"
    print_info "Docker和其他容器不受影响，保持原样。"
    echo ""
}

# 功能：查看Blockcast状态
check_status() {
    show_logo
    
    print_info "$PROJECT_NAME Docker 状态信息："
    echo ""
    
    if [ -d "$DOCKER_COMPOSE_DIR" ]; then
        cd "$DOCKER_COMPOSE_DIR" || {
            print_error "无法进入项目目录"
            exit 1
        }
        
        print_step "容器状态："
        if docker compose version &> /dev/null; then
            docker compose ps
        else
            docker-compose ps
        fi
        
        echo ""
        print_step "最近日志（最后20行）："
        if docker compose version &> /dev/null; then
            docker compose logs --tail=20
        else
            docker-compose logs --tail=20
        fi
        
        echo ""
        print_step "容器资源使用情况："
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.State}}" 2>/dev/null || \
        print_warning "无法获取资源使用统计"
    else
        print_warning "项目未安装或目录未找到"
        echo ""
        print_step "正在检查运行中的Blockcast容器..."
        docker ps --filter "name=blockcast" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" 2>/dev/null || \
        print_info "未找到Blockcast容器"
    fi
}

# 功能：重启Blockcast服务
restart_service() {
    show_logo
    
    print_step "正在重启 $PROJECT_NAME 服务..."
    
    if [ ! -d "$DOCKER_COMPOSE_DIR" ]; then
        print_error "项目目录未找到！"
        exit 1
    fi
    
    cd "$DOCKER_COMPOSE_DIR" || exit 1
    
    if docker compose version &> /dev/null; then
        docker compose restart
    else
        docker-compose restart
    fi
    
    if [ $? -eq 0 ]; then
        print_info "服务重启成功"
        echo ""
        print_step "当前服务状态："
        if docker compose version &> /dev/null; then
            docker compose ps
        else
            docker-compose ps
        fi
    else
        print_error "服务重启失败"
    fi
}

# 功能：显示使用帮助
show_help() {
    show_logo
    echo "使用方法："
    echo "  $0 [选项]"
    echo ""
    echo "选项："
    echo "  install     安装 Blockcast Docker"
    echo "  uninstall   卸载 Blockcast Docker"
    echo "  status      查看服务状态"
    echo "  restart     重启服务"
    echo "  help        显示此帮助信息"
    echo ""
    echo "示例："
    echo "  $0 install       # 安装Blockcast"
    echo "  $0 status        # 查看状态"
    echo "  $0               # 显示交互式菜单"
    echo ""
}

# 功能：显示主菜单
show_menu() {
    show_logo
    
    echo "请选择操作选项："
    echo "  1) 安装 Blockcast Docker"
    echo "  2) 卸载 Blockcast Docker"
    echo "  3) 查看服务状态"
    echo "  4) 重启服务"
    echo "  5) 显示帮助信息"
    echo "  6) 退出脚本"
    echo ""
    
    read -p "请输入你的选择（1-6）：" choice
    
    case $choice in
        1)
            install_blockcast
            ;;
        2)
            echo ""
            read -p "确定要卸载Blockcast Docker吗？此操作不可恢复！(y/N)：" -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                uninstall_blockcast
            else
                print_info "卸载操作已取消"
            fi
            ;;
        3)
            check_status
            ;;
        4)
            restart_service
            ;;
        5)
            show_help
            ;;
        6)
            print_info "感谢使用Blockcast安装脚本！"
            exit 0
            ;;
        *)
            print_error "无效的选择！"
            show_menu
            ;;
    esac
}

# 主程序入口：判断脚本运行参数
if [ $# -eq 0 ]; then
    # 无参数时显示菜单
    show_menu
else
    # 有参数时执行对应操作
    case $1 in
        install)
            install_blockcast
            ;;
        uninstall)
            echo ""
            read -p "确定要卸载Blockcast Docker吗？此操作不可恢复！(y/N)：" -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                uninstall_blockcast
            else
                print_info "卸载操作已取消"
            fi
            ;;
        status)
            check_status
            ;;
        restart)
            restart_service
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知参数: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
fi
