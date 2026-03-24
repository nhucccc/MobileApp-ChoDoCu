import paramiko, time

HOST = 'berlinmmo.site'
USER = 'root'
PASS = 'OhImryYT6v1C8mds'

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(HOST, username=USER, password=PASS, timeout=30)

def run(cmd, timeout=30):
    transport = ssh.get_transport()
    ch = transport.open_session()
    ch.get_pty()
    ch.settimeout(timeout)
    ch.exec_command(cmd)
    out = []
    while True:
        if ch.recv_ready():
            data = ch.recv(4096).decode('utf-8', errors='replace')
            for line in data.splitlines():
                print(line, flush=True)
                out.append(line)
        elif ch.exit_status_ready():
            while ch.recv_ready():
                data = ch.recv(4096).decode('utf-8', errors='replace')
                for line in data.splitlines():
                    print(line, flush=True)
                    out.append(line)
            break
        else:
            time.sleep(0.3)
    ch.close()
    return '\n'.join(out)

run('ls -lh /var/www/html/')
run('curl -s -o /dev/null -w "APK download HTTP: %{http_code}, size: %{size_download} bytes" https://berlinmmo.site/download/app-release.apk')

ssh.close()
