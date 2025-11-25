# Create keyrings directory if it doesn't exist
mkdir -p /etc/apt/keyrings
chmod 755 /etc/apt/keyrings

# Add Microsoft Edge GPG key
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/keyrings/microsoft.asc > /dev/null

# Add Microsoft Edge APT repository
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.asc] https://packages.microsoft.com/repos/edge stable main" \
    | tee /etc/apt/sources.list.d/msedge.list

# Update package lists
apt update

# Install Microsoft Edge Stable
apt install -y microsoft-edge-stable

