# probe requestの取得

下記にRSSIを取るための具体的な方策について記述している。今回はこれらを一つの実行ファイルにまとめているので、それを実行するだけで良い。



## 機材調整
monitorモードになっているwifiモジュールが必要．

なので，SSH接続用とは別にwifiインターフェイスを用意しておく

ここで，wifiインターフェイスはraspberry pi 起動後に接続するようにする．wifi接続してからだと接続を外した際にwifiごと切ってしまう可能性があるからだ．

本実験ではTP-Link T3U Plusを用いている．

下記ドライバーをインストール
https://github.com/morrownr/88x2bu-20210702

## 接続されているwifiインターフェイスを見分ける
ip link showで現在認識しているwifiインターフェイスの一覧が表示できる

3: wlan0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN mode DORMANT group default qlen 1000
    link/ether e4:5f:01:fd:e6:79 brd ff:ff:ff:ff:ff:ff
4: wlan1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT group default qlen 1000
    link/ether a8:6e:84:da:c7:21 brd ff:ff:ff:ff:ff:ff

このmacアドレスから会社名を検索し，Raspberry piのものでない方が外部接続されたwifiモジュールである．

ここで検索できる https://uic.jp/mac/address/a86e84/

macアドレスは最初の3つのコードだけでいい．ここでは．

Vendor name: Raspberry Pi Trading Ltd  
MAC Prefix: E4:5F:01

Vendor name: TP-LINK CORPORATION PTE. LTD.  
MAC Prefix: A8:6E:84

とでた．よって，wlan1が外部インターフェイスである．

これをモニターモードに切り替える．

## モニターモードへの切り替え

wlan1を切り替えるなら

sudo ip link set wlan1 down  
sudo iw dev wlan1 set type monitor  
sudo ip link set wlan1 up

ここで接続が切れたら，sshに接続していたwifiを切ってしまったことになる．もう一度やり直し

処理が終わったら，
iwconfigで今の接続状態を確認
mode:monitorになっていれば成功

## キャプチャのコマンド実行

nohup unbuffer sudo tshark -i wlan1 -Y "wlan.fc.type_subtype == 4" -T fields -e frame.time_epoch -e wlan.sa -e radiotap.dbm_antsignal >> output.txt &

このコマンドで．output.txtにprobe requestのMACアドレスと受信時刻とRSSIが記録される．
（時間はUNIX時間である）

## キャプチャの終了

ps aux | grep tsharkでプロセスIDを確認し，killで終了する．

## output.txtファイルの内容を削除

rm output.txt と touch output.txtでファイルを空にする。
同時に実行するには rm output.txt && touch output.txt とする．

## 補足：androidでのランダムmacアドレス

設定が書き換わるのはwifiに接続するときだけで，接続していないときはmacアドレスが変わることはない．
（乗車中の車両で頻繁にmacアドレスが変わることは考えづらい．）
