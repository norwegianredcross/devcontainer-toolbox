# vpn readme


az login
az login --use-device-code
az login --allow-no-subscriptions

az account get-access-token

# see tun device listed

/sbin/ifconfig

```plaintext
tun0: flags=4241<UP,POINTOPOINT,NOARP,MULTICAST>  mtu 1500
        unspec 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  txqueuelen 500  (UNSPEC)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```        

## must install ping
sudo apt install iputils-ping

