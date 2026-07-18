# Test systemd failure block

```bash
# Create a failing service
sudo tee /etc/systemd/system/fail-test.service << 'EOF'
[Service]
Type=oneshot
ExecStart=/bin/false
EOF

sudo systemctl daemon-reload
sudo systemctl start fail-test.service
```

Block will show `❌ 1`. Click it to analyze with opencode.

```bash
# Clean up
sudo systemctl reset-failed fail-test.service
sudo rm /etc/systemd/system/fail-test.service
sudo systemctl daemon-reload
```
