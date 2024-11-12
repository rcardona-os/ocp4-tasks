### Deployment and Configuration of Simple DHCP server


- 0. Step 1: Install DHCP Server
First, you need to install the DHCP server package. You can do this using dnf (the package manager in RHEL8):

```bash
$ sudo dnf install dhcp-server
```

- 1. Step 2: Configure DHCP Server
After installing the DHCP server, you'll need to configure it. The configuration file for the DHCP server is typically located at /etc/dhcp/dhcpd.conf, not dhclient.conf (which is for DHCP clients).

Here's a simple configuration for your requirements. This configuration will allow the DHCP server to assign IP addresses from 192.168.0.1 to 192.168.0.14 within the subnet 192.168.0.0/28.

Edit the /etc/dhcp/dhcpd.conf file with a text editor.

```bash
$ cat /etc/dhcp/dhcpd.conf
subnet 192.168.0.0 netmask 255.255.255.240 {
    range 192.168.0.1 192.168.0.14;  # Range of IPs to assign to clients
    option routers 192.168.0.1;      # Default gateway IP address
    option subnet-mask 255.255.255.240;  # Subnet mask
    option domain-name-servers 192.168.0.1;  # DNS servers
    default-lease-time 600;   # Lease time in seconds
    max-lease-time 7200;      # Maximum lease time in seconds
}
```

- 2. Step 3: Start and Enable DHCP Server
Once you have configured the DHCP server, you need to start and enable it so that it runs on system boot:

```bash
$ sudo systemctl start dhcpd
```
```bash
$ sudo systemctl enable dhcpd
```

- 3. Step 4: Verify the DHCP Server
To ensure that your DHCP server is running correctly, check its status:

```bash
$ sudo systemctl status dhcpd
```

You can also check the DHCP server logs for any errors or confirmation that it is handing out IP addresses properly:

```bash
$ journalctl -u dhcpd
```
Note: Make sure that your firewall settings are configured to allow DHCP traffic. DHCP typically uses UDP port 67 for the DHCP server and UDP port 68 for the DHCP client.

Here's how you can adjust the firewall settings:

```bash
$ sudo firewall-cmd --add-service=dhcp --permanent
$ sudo firewall-cmd --reload
```