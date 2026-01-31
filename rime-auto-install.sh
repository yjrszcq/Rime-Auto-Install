#!/bin/bash

set -e

GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

PROGRESS_FILE="/tmp/rime_install_progress"

hello(){
  echo -e "\n${YELLOW}在 Arch Linux 上安装 Rime 输入法${NC}"
}

up_to_date(){
  echo "up_to_date" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：使系统保持最新${NC}"
  echo -e "\n" | sudo pacman -Syu
  echo -e "\n${GREEN}完成：使系统保持最新${NC}"
}

install_env(){
  echo "install_env" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：安装环境${NC}"
  echo -e "\n" | sudo pacman -S yay fakeroot unzip plasma-x11-session
  echo -e "\n${GREEN}完成：安装环境${NC}"
}

install_fcitx5(){
  echo "install_fcitx5" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：安装 fcitx5${NC}"
  echo -e "\n" | sudo pacman -S fcitx5 fcitx5-qt fcitx5-gtk fcitx5-lua fcitx5-material-color fcitx5-chinese-addons
  {
    grep -qF 'GTK_IM_MODULE=fcitx' /etc/environment || echo 'GTK_IM_MODULE=fcitx'
    grep -qF 'QT_IM_MODULE=fcitx' /etc/environment || echo 'QT_IM_MODULE=fcitx'
    grep -qF 'XMODIFIERS=@im=fcitx' /etc/environment || echo 'XMODIFIERS=@im=fcitx'
    grep -qF 'SDL_IM_MODULE=fcitx' /etc/environment || echo 'SDL_IM_MODULE=fcitx'
  } | sudo tee -a /etc/environment > /dev/null
  echo -e "\n${GREEN}完成：安装 fcitx5${NC}"
}

install_rime(){
  echo "install_rime" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：安装 rime${NC}"
  echo -e "\n" | yay -S  fcitx5-rime xcb-imdkit kcm-fcitx5 noto-fonts-emoji
  echo -e "\n${GREEN}完成：安装 rime${NC}"
}

download_oh_my_rime(){
  echo "download_oh_my_rime" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：下载 oh my rime${NC}"
  wget https://github.com/Mintimate/oh-my-rime/archive/refs/heads/main.zip -O /tmp/oh-my-rime.zip
  echo -e "\n${GREEN}完成：下载 oh my rime${NC}"
}

install_oh_my_rime(){
  echo "install_oh_my_rime" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：安装 oh my rime${NC}"
  mkdir -p ~/.local/share/fcitx5
  rm -rf ~/.local/share/fcitx5/oh-my-rime-main
  rm -rf ~/.local/share/fcitx5/rime
  unzip -d ~/.local/share/fcitx5 /tmp/oh-my-rime.zip
  mv ~/.local/share/fcitx5/oh-my-rime-main ~/.local/share/fcitx5/rime
  echo -e "\n${GREEN}完成：安装 oh my rime${NC}"
}

configure_fcitx5_rime(){
  echo "configure_fcitx5_rime" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：配置 fcitx5 使用 Rime${NC}"

  mkdir -p ~/.config/fcitx5
  local profile=~/.config/fcitx5/profile

  # 备份原 profile
  if [[ -f "$profile" ]]; then
    local backup="${profile}.bak.$(date +%s)"
    cp "$profile" "$backup"
    echo -e "${BLUE}已备份原有 profile 为：${backup}${NC}"
  fi

  # 尝试获取当前键盘布局（获取失败就用 cn）
  local layout="cn"
  if command -v localectl >/dev/null 2>&1; then
    layout=$(localectl status 2>/dev/null | awk -F: '/X11 Layout/ {gsub(/ /,"",$2); print $2}')
    [[ -z "$layout" ]] && layout="cn"
  fi

  cat > "$profile" <<EOF
[Groups/0]
Name=Default
Default Layout=${layout}
DefaultIM=rime

[Groups/0/Items/0]
Name=rime
Layout=

[GroupOrder]
0=Default
EOF

  echo -e "${BLUE}已自动写入 ~/.config/fcitx5/profile，默认输入法为 Rime${NC}"

  echo -e "\n${GREEN}完成：配置 fcitx5 使用 Rime${NC}"
}

launch_fcitx5(){
  echo "launch_fcitx5" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：重启 fcitx5${NC}"
  # 先杀掉已有进程（如果有）
  if pgrep -x fcitx5 >/dev/null 2>&1; then
    pkill -x fcitx5 || true
    sleep 1
  fi
  nohup /usr/bin/fcitx5 > /tmp/fcitx5-output.log 2>&1 &
  echo -e "\n${GREEN}完成：重启 fcitx5${NC}"
}

complete(){
  touch ~/.local/share/fcitx5/rime/.auto-install-complete
  echo "complete" > "$PROGRESS_FILE"
  echo -e "\n${YELLOW}==============================================${NC}"
  echo -e "\n${GREEN}安装完成！请重启电脑，以完成 Rime 输入法的安装${NC}"
  echo -e "\n${YELLOW}==============================================\n${NC}"
  echo -e "\n${YELLOW}注意：目前最新的 Arch Linux 使用 wayland 时，部分软件无法输入中文，推荐使用 X11\n${NC}"
  echo -e "${BLUE}1. 在 重启电脑后的登录界面左下角，选择 'Plasma (X11)'${NC}"
  echo -e "\n${YELLOW}注意：若仍要使用 wayland，可能需要继续进行以下操作\n${NC}"
  echo -e "${BLUE}1. 在 '系统设置 > 键盘 > 虚拟键盘' 中开启虚拟键盘 'fcitx5'${NC}"
  echo -e "${BLUE}2. 在 '/etc/profile' 中删除 'GTK_IM_MODULE' 与 'QT_IM_MODULE' 环境变量配置${NC}"
  echo -e "${BLUE}3. 注销并重新进入桌面${NC}"
}

main(){
  hello
  if [[ -f ~/.local/share/fcitx5/rime/.auto-install-complete ]]; then
    complete
    exit 0
  fi
  local progress="up_to_date"
  if [[ -f "$PROGRESS_FILE" ]]; then
    progress=$(cat "$PROGRESS_FILE")
    echo -e "\n${BLUE}已恢复上次执行的进度！${NC}"
  fi
  case $progress in
    "up_to_date")
      up_to_date
      ;&
    "install_env")
      install_env
      ;&
    "install_fcitx5")
      install_fcitx5
      ;&
    "install_rime")
      install_rime
      ;&
    "download_oh_my_rime")
      download_oh_my_rime
      ;&
    "install_oh_my_rime")
      install_oh_my_rime
      ;&
    "configure_fcitx5_rime")
      configure_fcitx5_rime
      ;&
    "launch_fcitx5")
      launch_fcitx5
      ;&
    "complete")
      complete
      ;;
    *)
      echo -e "${YELLOW}未知的进度状态，重新开始执行${NC}"
      up_to_date
      install_env
      install_fcitx5
      install_rime
      download_oh_my_rime
      install_oh_my_rime
      configure_fcitx5_rime
      launch_fcitx5
      complete
      ;;
  esac
}

main
