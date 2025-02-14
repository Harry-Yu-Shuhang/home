cd /etc/nginx/sites-available

sudo vim homepage

写入以下：

# 1. HTTP 端口：自动跳转到 HTTPS
server {
    listen 80;
    server_name harryyu.work;
    
    return 301 https://$host$request_uri;
}

# 2. 让 Nginx 监听 443 端口，并反向代理到 12210 端口
server {
    listen 443 ssl;
    server_name harryyu.work;

    # SSL 证书路径（换成你的实际路径）
    ssl_certificate /home/admin/.ssh/harryyu.work.pem;
    ssl_certificate_key /home/admin/.ssh/harryyu.work.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:12210;  # 这里反向代理到 12210
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# 3. 个人主页直接监听 12210 端口（不受 Nginx 影响）
server {
    listen 12210;
    server_name harryyu.work;

    root /home/admin/homepage;
    index index.html;

    location / {
        try_files $uri /index.html;
    }
}



sudo rm /etc/nginx/sites-enabled/homepage
sudo ln -s /etc/nginx/sites-available/homepage /etc/nginx/sites-enabled/

sudo nginx -t

sudo systemctl restart nginx

