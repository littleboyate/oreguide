#!/bin/bash
INSTALLATION_DIR=$(dirname "$(realpath "$0")")
sudo apt update -y
sudo apt-get update
sudo apt-get install -y build-essential gapt update
sudo apt install build-essential -y
sudo apt install screen -y
sudo apt-get install bc -y
sudo apt-get install jq -y

curl https://sh.rustup.rs -sSf | sh

. "$HOME/.cargo/env" 

sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"

source ~/.profile

#cargo install ore-cli

source ~/.profile
echo '#!/bin/bash' > master_miner.sh

NUM=1

solana-keygen new -o id.json
solana address -k id.json


read -p "Please enter the RPC URL: " rpc_url

read -p "Please enter the gas fee: " gas_fee

. "$HOME/.cargo/env" 

for ((i=1; i<=$NUM; i++))
do
  tee mine$i.sh > /dev/null <<EOF
  while true; do
    echo "Mining $i starting..."
    ore --rpc "$rpc_url" --keypair ${INSTALLATION_DIR}/id.json --priority-fee ${gas_fee} mine --threads 15
    echo "Mining $i finished."
  done
EOF
  echo "sh mine$i.sh >> miner.log 2>&1 & echo \$! >> miner.pid" >> master_miner.sh
done
chmod ug+x mine*.sh

tee add_miner.sh > /dev/null <<EOF
  highest=0
  for file in mine*.sh; do
    num=\${file//[^0-9]/}
    if [ -n "\$num" ] && [ "\$num" -gt "\$highest" ]; then
      highest=\$num
    fi
  done
  i=\$((highest+1))
  echo '#!/bin/bash' > mine\$i.sh
  echo "while true; do" >> mine\$i.sh
  echo "  echo "Mining \$i starting..."" >> mine\$i.sh
  echo "  ore --rpc "$rpc_url" --keypair ${INSTALLATION_DIR}/id.json --priority-fee \${gas_fee} mine --threads 15" >> mine\$i.sh
  echo "  echo "Mining \$i finished."" >> mine\$i.sh
  echo "done" >> mine\$i.sh
  chmod ug+x mine\$i.sh
  echo "sh mine\$i.sh >> miner.log 2>&1 & echo \\\$! >> miner.pid" >> master_miner.sh
EOF
chmod ug+x add_miner.sh

tee add_wallet.sh > /dev/null <<EOF
  highest=0
  for file in mine*.sh; do
    num=\${file//[^0-9]/}
    if [ -n "\$num" ] && [ "\$num" -gt "\$highest" ]; then
      highest=\$num
    fi
  done
  i=\$((highest+1))
  solana-keygen new -o id\$i.json
  solana address -k id\$i.json

  read -p "Please enter the RPC URL: " rpc_url

  read -p "Please enter the gas fee: " gas_fee

  echo '#!/bin/bash' > mine\$i.sh
  echo "while true; do" >> mine\$i.sh
  echo "  echo "Mining \$i starting..."" >> mine\$i.sh
  echo "  ore --rpc \$rpc_url --keypair ${INSTALLATION_DIR}/id\$i.json --priority-fee \${gas_fee} mine --threads 15" >> mine\$i.sh
  echo "  echo "Mining \$i finished."" >> mine\$i.sh
  echo "done" >> mine\$i.sh
  chmod ug+x mine\$i.sh
  echo "Address ${INSTALLATION_DIR}/id\$i.json"
  solana address -k ${INSTALLATION_DIR}/id\$i.json
  echo "sh mine\$i.sh >> miner.log 2>&1 & echo \\\$! >> miner.pid" >> master_miner.sh

EOF
chmod ug+x add_wallet.sh

tee start_miner.sh > /dev/null <<EOF
  sh master_miner.sh
EOF
chmod ug+x start_miner.sh

tee stop_miner.sh > /dev/null <<EOF
  kill \$(cat miner.pid)
  pkill ore
  rm miner.pid
EOF
chmod ug+x stop_miner.sh

tee list_addresses.sh > /dev/null <<EOF
  for key in id*.json; do
    echo "Address \$key: "
    solana address -k ${INSTALLATION_DIR}/\$key
  done
EOF
chmod ug+x list_addresses.sh

tee check_rewards.sh > /dev/null <<EOF
  for key in id*.json; do
    echo "Rewards \$key: "
    solana address -k ${INSTALLATION_DIR}/\$key
    ore --keypair ${INSTALLATION_DIR}/\$key rewards
  done
EOF
chmod ug+x check_rewards.sh

tee claim_rewards.sh > /dev/null <<EOF
  for key in id*.json; do
    rewards=\$(ore --keypair ${INSTALLATION_DIR}/\$key rewards | tr -dc '0-9.')
    echo \$rewards
    if [ "\$rewards" \> "0.01" ]; then
      echo "Claiming \$key: " >> claim_rewards.log
      ore --rpc "$rpc_url" --keypair ${INSTALLATION_DIR}/\$key --priority-fee ${gas_fee} claim >> claim_rewards.log &
    fi
  done
EOF
chmod ug+x claim_rewards.sh

tee setup_log.sh > /dev/null <<EOF
  screen -S log_mine
  sudo tail -f miner.log
EOF
chmod ug+x setup_log.sh

sudo tee /etc/logrotate.d/ore > /dev/null <<EOF
  $INSTALLATION_DIR/miner.log {
    rotate 5
    hourly
    missingok
    notifempty
    copytruncate
    compress
    compresscmd /bin/gzip
  }
EOF