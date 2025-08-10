#!/bin/bash

# 自动上传GitHub代码脚本
# 作者: Silence Breaker
# 创建时间: 2025年8月10日

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否在Git仓库中
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "当前目录不是Git仓库！"
        exit 1
    fi
}

# 检查是否有远程仓库
check_remote() {
    if ! git remote get-url origin > /dev/null 2>&1; then
        print_error "没有找到远程仓库origin！"
        exit 1
    fi
}

# 显示当前状态
show_status() {
    print_info "当前Git状态："
    git status --short
    echo
}

# 添加文件
add_files() {
    print_info "添加所有更改的文件..."
    git add .
    
    # 检查是否有文件被添加
    if git diff --cached --quiet; then
        print_warning "没有检测到任何更改，无需提交。"
        return 1
    fi
    
    print_success "文件添加完成！"
    return 0
}

# 提交更改
commit_changes() {
    # 获取提交信息
    if [ -n "$1" ]; then
        commit_message="$1"
    else
        echo -n "请输入提交信息 (回车使用默认信息): "
        read user_input
        if [ -n "$user_input" ]; then
            commit_message="$user_input"
        else
            commit_message="Auto update: $(date '+%Y-%m-%d %H:%M:%S')"
        fi
    fi
    
    print_info "提交更改: $commit_message"
    if git commit -m "$commit_message"; then
        print_success "提交成功！"
        return 0
    else
        print_error "提交失败！"
        return 1
    fi
}

# 推送到远程仓库
push_to_remote() {
    local branch_name
    branch_name=$(git branch --show-current)
    print_info "推送到远程仓库 (分支: $branch_name)..."
    
    if git push origin "$branch_name"; then
        print_success "推送成功！代码已上传到GitHub！"
        return 0
    else
        print_error "推送失败！请检查网络连接和权限。"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] [提交信息]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -s, --status   仅显示Git状态"
    echo "  -f, --force    强制推送 (使用 git push --force)"
    echo ""
    echo "示例:"
    echo "  $0                           # 交互式运行"
    echo "  $0 \"更新Task1文档\"          # 使用指定的提交信息"
    echo "  $0 -s                        # 仅显示状态"
    echo "  $0 -f \"紧急修复\"            # 强制推送"
}

# 强制推送模式
force_push=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--status)
            check_git_repo
            show_status
            exit 0
            ;;
        -f|--force)
            force_push=true
            shift
            ;;
        *)
            commit_message="$1"
            shift
            ;;
    esac
done

# 主函数
main() {
    print_info "开始自动上传流程..."
    echo
    
    # 检查Git仓库
    check_git_repo
    check_remote
    
    # 显示当前状态
    show_status
    
    # 添加文件
    if ! add_files; then
        exit 0
    fi
    
    # 提交更改
    if ! commit_changes "$commit_message"; then
        exit 1
    fi
    
    # 推送到远程仓库
    if [ "$force_push" = true ]; then
        print_warning "使用强制推送模式..."
        local branch_name
        branch_name=$(git branch --show-current)
        if git push --force origin "$branch_name"; then
            print_success "强制推送成功！代码已上传到GitHub！"
        else
            print_error "强制推送失败！"
            exit 1
        fi
    else
        if ! push_to_remote; then
            exit 1
        fi
    fi
    
    echo
    print_success "所有操作完成！✨"
    print_info "远程仓库地址: $(git remote get-url origin)"
}

# 运行主函数
main "$@"
