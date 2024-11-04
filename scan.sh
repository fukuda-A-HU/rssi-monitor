# TP-LinkのMACプレフィックス
TPLINK_PREFIX="A8:6E:84"

# インターフェース名の初期化
interface_name=""

# TP-Linkインターフェースが見つかるまで待機
while :; do
  # インターフェースを取得してTP-Linkのものを検索
  for interface in $(iw dev | awk '$1=="Interface"{print $2}'); do
    mac_address=$(cat /sys/class/net/$interface/address | tr '[:lower:]' '[:upper:]')
    if [[ $mac_address == $TPLINK_PREFIX* ]]; then
      interface_name=$interface
      echo "TP-Linkインターフェース $interface_name が見つかりました。"
      break 2  # 外側のwhileループも抜け出す
    fi
  done

  # インターフェースが見つからない場合は待機して再試行
  echo "TP-Linkインターフェースが見つかるのを待機しています..."
  sleep 5  # 5秒待機して再試行
done

# tsharkプロセスを取得し、killする
for pid in $(ps aux | grep '[t]shark' | awk '{print $2}'); do
  kill "$pid" 2>/dev/null || true
done

# output.txtを削除
rm -f output.txt
touch output.txt

# TP-Linkインターフェースをモニターモードに設定
# wifiの接続を切断
# sudo nmcli device disconnect $interface_name
sudo ip link set $interface_name down
sudo iw dev $interface_name set type monitor
sudo ip link set $interface_name up
echo "$interface_name をモニターモードに設定しました。"

# キャプチャ開始
echo "キャプチャを開始します..."
nohup unbuffer sudo tshark -i $interface_name -Y "wlan.fc.type_subtype == 4" -T fields -e frame.time_epoch -e wlan.sa -e radiotap.dbm_antsignal >> output.txt &
echo "キャプチャが開始されました。データはoutput.txtに保存されます。"

# 起動時にpython /home/fukuda/file_send.pyを実行
python file_send.py &