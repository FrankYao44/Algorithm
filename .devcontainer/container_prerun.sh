# mkdir -p /home/coder/.ssh
# sudo cp /home/coder/.ssh_host/* /home/coder/.ssh
# sudo chown -R coder:coder /workspace
# sudo chown -R coder:coder /home/coder/.ssh
# sudo chmod 700 /home/coder/.ssh 
# sudo chmod 600 /home/coder/.ssh/*
# sudo rm /home/coder/.ssh/known_hosts
# sudo rm /home/coder/.ssh/known_hosts.old


# ssh -o StrictHostKeyChecking=accept-new  -T git@github.com 
# 设置 git 代理与容器环境变量一致
# if [ -n "$http_proxy" ]; then
#     git config --global http.proxy "$http_proxy"
#     git config --global https.proxy "$https_proxy"
#     echo "Git proxy set to $http_proxy"
# else
#     echo "http_proxy not set, skipping git proxy configuration"
# fi


git config --global user.email "fy44.zxcs@gmail.com" && git config --global user.name "frankyao44"