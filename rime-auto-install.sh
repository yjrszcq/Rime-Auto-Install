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
  echo -e "\n" | sudo pacman -S yay fakeroot unzip
  echo -e "\n${GREEN}完成：安装环境${NC}"
}

install_fcitx5(){
  echo "install_fcitx5" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：安装 fcitx5${NC}"
  echo -e "\n" | sudo pacman -S fcitx5 fcitx5-qt fcitx5-gtk fcitx5-lua fcitx5-material-color fcitx5-chinese-addons
  {
    grep -qF 'export XMODIFIERS="@im=fcitx5"' /etc/profile || echo 'export XMODIFIERS="@im=fcitx5"'
    grep -qF 'export GTK_IM_MODULE="fcitx5"' /etc/profile || echo 'export GTK_IM_MODULE="fcitx5"'
    grep -qF 'export QT_IM_MODULE="fcitx5"' /etc/profile || echo 'export QT_IM_MODULE="fcitx5"'
  } | sudo tee -a /etc/profile > /dev/null
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

launch_fcitx5(){
  echo "start_fcitx5" > "$PROGRESS_FILE"
  echo -e "\n${GREEN}开始：启动 fcitx5${NC}"
  nohup /usr/bin/fcitx5 > /tmp/fcitx5-output.log 2>&1 &
  echo -e "\n${GREEN}完成：启动 fcitx5${NC}"
}

complete(){
  touch ~/.local/share/fcitx5/rime/.auto-install-complete
  echo "complete" > "$PROGRESS_FILE"
  echo -e "\n${YELLOW}安装完成！请手动进行以下操作，以完成 Rime 输入法的启用\n${NC}"
  echo -e "${BLUE}01. 右键任务栏上的键盘图标${NC}"
  echo -e "${BLUE}02. 点击配置${NC}"
  echo -e "${BLUE}03. 叉掉所有输入法${NC}"
  echo -e "${BLUE}04. 点击添加输入法${NC}"
  echo -e "${BLUE}05. 选择中州韵${NC}"
  echo -e "${BLUE}06. 点击添加${NC}"
  echo -e "${BLUE}07. 点击应用${NC}"
  echo -e "${BLUE}08. 右键任务栏上的键盘图标${NC}"
  echo -e "${BLUE}09. 点击重新启动${NC}"
  echo -e "${BLUE}10. 重启电脑${NC}"
  echo -e "\n${YELLOW}注意：目前最新的 Arch Linux 使用 wayland 时，可能需要继续进行以下操作\n${NC}"
  echo -e "\n${BLUE}11. 在 '系统设置 > 键盘 > 虚拟键盘' 中开启虚拟键盘 'fcitx5'\n${NC}"
  echo -e "\n${BLUE}12. 在 '/etc/profile' 中删除 'GTK_IM_MODULE' 与 'QT_IM_MODULE' 环境变量配置\n${NC}"
  echo -e "\n${BLUE}13. 注销并重新进入桌面\n${NC}"
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
      launch_fcitx5
      complete
      ;;
  esac
}

main
