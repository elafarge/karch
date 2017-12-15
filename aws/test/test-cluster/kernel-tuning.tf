# Kernel parameters to enforce on our nodes via a systemd hook
data "template_file" "webserver-sysctl-parameters" {
  count = "${length(var.webserver-sysctl-parameters)}"

  template = "      ExecStartPre=/usr/sbin/sysctl -w ${element(var.webserver-sysctl-parameters, count.index)}"
}

variable "webserver-sysctl-parameters" {
  type = "list"

  default = [
    # Number of file descriptors on the system
    "fs.file-max=2097152",

    # Max number of orphaned TCP sockets
    "net.ipv4.tcp_max_orphans=60000",

    # Do not save metrics when connexion are closed to spare CPU&IO time
    "net.ipv4.tcp_no_metrics_save=1",

    # Enable TCP window scaling
    # https://en.wikipedia.org/wiki/TCP_window_scale_option
    "net.ipv4.tcp_window_scaling=1",

    # As per RFC 1323, enabling round trip measurements might feel like a good idea at the age of fiber optics
    "net.ipv4.tcp_timestamps=1",

    # Enable select acknowledgments:
    "net.ipv4.tcp_sack=1",

    // Allowed local port range
    "net.ipv4.ip_local_port_range=1024 65535",

    # Maximum number of remembered connection requests, which did not yet
    # receive an acknowledgment from connecting client.
    "net.ipv4.tcp_max_syn_backlog=10240",

    # Choose the HTCP congestion control algorithm
    "net.ipv4.tcp_congestion_control=htcp",

    # recommended for hosts with jumbo frames enabled
    "net.ipv4.tcp_mtu_probing=1",

    # Number of times SYNACKs for passive TCP connection.
    "net.ipv4.tcp_synack_retries=2",

    # Protect Against TCP Time-Wait
    "net.ipv4.tcp_rfc1337=1",

    # Decrease the time default value for tcp_fin_timeout connection
    "net.ipv4.tcp_fin_timeout=15",

    # Increase number of incoming connections
    # somaxconn defines the number of request_sock structures
    # allocated per each listen call. The
    # queue is persistent through the life of the listen socket.
    "net.core.somaxconn=1024",                     // or more ?

    # Increase number of incoming connections backlog queue
    # Sets the maximum number of packets, queued on the INPUT
    # side, when the interface receives packets faster than
    # kernel can process them.
    "net.core.netdev_max_backlog=65536",           // or more ?

    # Increase the maximum amount of option memory buffers
    "net.core.optmem_max=25165824",

    # Increase the maximum total buffer-space allocatable
    # This is measured in units of pages (4096 bytes)
    "net.ipv4.tcp_mem='65536 131072 262144'",

    "net.ipv4.udp_mem='65536 131072 262144'",

    # Default Socket Receive Buffer
    "net.core.rmem_default=25165824",

    # Maximum Socket Receive Buffer
    "net.core.rmem_max=25165824 ",

    # Increase the read-buffer space allocatable (minimum size,
    # initial size, and maximum size in bytes)
    "net.ipv4.tcp_rmem='20480 12582912 25165824'",

    "net.ipv4.udp_rmem_min=16384",

    # Default Socket Send Buffer
    "net.core.wmem_default=25165824",

    # Maximum Socket Send Buffer
    "net.core.wmem_max=25165824",

    # Increase the write-buffer-space allocatable
    "net.ipv4.tcp_wmem='20480 12582912 25165824'",

    "net.ipv4.udp_wmem_min=16384",

    # Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
    "net.ipv4.tcp_max_tw_buckets=1440000",

    "net.ipv4.tcp_tw_reuse=1",
  ]
}
