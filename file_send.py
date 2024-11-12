import smtplib
import socket
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import os
import time

def is_connected():
    """インターネット接続を確認する関数"""
    try:
        # GoogleのDNSサーバーに接続を試みる
        socket.create_connection(("8.8.8.8", 53), timeout=5)
        return True
    except OSError:
        return False

def send_email_with_attachment(to_address, subject, body, attachment_path):
    """指定されたファイルを添付したメールを送信する関数"""
    from_address = "maimai53kantai@gmail.com"  # 送信元のメールアドレス
    password = "kqig qgae ixxn iybo"  # メールアカウントのパスワード

    # メールの設定
    msg = MIMEMultipart()
    msg['From'] = from_address
    msg['To'] = to_address
    msg['Subject'] = subject

    # メールの本文を設定
    msg.attach(MIMEText(body, 'plain'))

    # 添付ファイルの処理
    if os.path.isfile(attachment_path):
        with open(attachment_path, "rb") as attachment_file:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment_file.read())
            encoders.encode_base64(part)
            part.add_header('Content-Disposition', f'attachment; filename={os.path.basename(attachment_path)}')
            msg.attach(part)

    # SMTPサーバーに接続してメールを送信
    try:
        with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:  # Gmail用のSMTPサーバーとポート
            server.login(from_address, password)
            server.sendmail(from_address, to_address, msg.as_string())
        # print("メールが送信されました。")
    except Exception as e:
        # print(f"メール送信中にエラーが発生しました: {e}")
        pass

# メインのループ
def main():

    while True:
        # インターネット接続を確認
        if is_connected():
            send_email_with_attachment(
                to_address="fukuda.eiki.l8@elms.hokudai.ac.jp",  # 送信先のメールアドレス
                subject="WIFI実験データ送信",
                body="実験データを送信します。",
                attachment_path="wifi_output.txt"  # 添付ファイルのパス
            )
            time.sleep(120)

            # send_email_with_attachment(
            #    to_address="fukuda.eiki.l8@elms.hokudai.ac.jp",  # 送信先のメールアドレス
            #    subject="BLE実験データ送信",
            ##    body="実験データを送信します。",
            #    attachment_path="ble_output.txt"  # 添付ファイルのパス
            #)
            time.sleep(120)

        else:
            # print("インターネットに接続されていません。")

            time.sleep(10)

if __name__ == "__main__":
    main()