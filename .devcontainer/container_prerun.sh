echo "0"
mkdir -p /home/coder/.ssh
sudo cp /home/coder/.ssh_host/* /home/coder/.ssh
echo "1" 
sudo chown -R coder:coder /workspace
sudo chown -R coder:coder /home/coder/.ssh
echo "2"
sudo chmod 700 /home/coder/.ssh 
sudo chmod 600 /home/coder/.ssh/*
echo "3"
sudo rm /home/coder/.ssh/known_hosts
sudo rm /home/coder/.ssh/known_hosts.old