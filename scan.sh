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

# hcitoolプロセスを取得し、killする
for pid in $(ps aux | grep '[h]citool' | awk '{print $2}'); do
  kill "$pid" 2>/dev/null || true
done

# output.txtを削除
rm -f wifi_output.txt
touch wifi_output.txt
rm -f ble_output.txt
touch ble_output.txt


# wifiの接続を切断
status=$(nmcli device status | grep "$interface_name" | awk '{print $3}')
# 状態に応じて処理を分岐
if [ "$status" = "connected" ]; then
    echo "$interface_name is active. Disconnecting..."
    sudo nmcli device disconnect "$interface_name"
    echo "$interface_name has been disconnected."
elif [ "$status" = "disconnected" ]; then
    echo "$interface_name is already disconnected. Skipping disconnect."
else
    echo "$interface_name is in an unknown state: $status"
fi

# TP-Linkインターフェースをモニターモードに設定
sudo ip link set $interface_name down
sudo iw dev $interface_name set type monitor
sudo ip link set $interface_name up
echo "$interface_name をモニターモードに設定しました。"

# キャプチャ開始
echo "キャプチャを開始します..."

# WiFiのキャプチャ（末尾にWIFIを付けてwifi_output.txtに保存）
nohup unbuffer sudo tshark -i wlan1 -Y "wlan.fc.type_subtype == 4" -T fields -e frame.time_epoch -e wlan.sa -e radiotap.dbm_antsignal >> wifi_output.txt &
# BLEのキャプチャ（末尾にBLEを付けてble_output.txtに保存）
# nohup unbuffer sudo tshark -i bluetooth0 -V | awk '/Epoch Time:/ {timestamp = $3} /BD_ADDR:/ {address = $2} /RSSI:/ {rssi = $2; print timestamp "\t" address "\t" rssi "\tBLE"; timestamp=""; address=""; rssi=""}' >> ble_output.txt 2>&1 &


echo "キャプチャが開始されました。データはble_output.txt、wifi_output.txtに保存されます。"

# 起動時にpython /home/fukuda/file_send.pyを実行
python file_send.py &