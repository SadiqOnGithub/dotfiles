#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <netinet/ip_icmp.h>
#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <linux/if_ether.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <pthread.h>

#define MAX_PROTOCOLS 256
#define MAX_NAME_LEN 64
#define BUFFER_SIZE 65536

typedef struct {
    char name[MAX_NAME_LEN];
    unsigned long frames;
    unsigned long bytes;
    unsigned long last_frames;
    unsigned long last_bytes;
    double rate_frames;
    double rate_bytes;
    int level;
} protocol_stats_t;

typedef struct {
    protocol_stats_t protocols[MAX_PROTOCOLS];
    int count;
    int running;
    pthread_mutex_t mutex;
    char interface[32];
} monitor_t;

static monitor_t monitor = {0};

void signal_handler(int sig) {
    monitor.running = 0;
    printf("\nShutting down...\n");
}

void clear_screen() {
    system("clear");
}

char* bytes_to_human(unsigned long bytes, char* buffer) {
    const char* units[] = {"B", "KB", "MB", "GB", "TB"};
    double size = bytes;
    int unit = 0;
    
    while (size >= 1024 && unit < 4) {
        size /= 1024;
        unit++;
    }
    
    if (unit == 0) {
        snprintf(buffer, 16, "%lu %s", bytes, units[unit]);
    } else {
        snprintf(buffer, 16, "%.1f %s", size, units[unit]);
    }
    
    return buffer;
}

int find_protocol(const char* name) {
    pthread_mutex_lock(&monitor.mutex);
    for (int i = 0; i < monitor.count; i++) {
        if (strcmp(monitor.protocols[i].name, name) == 0) {
            pthread_mutex_unlock(&monitor.mutex);
            return i;
        }
    }
    pthread_mutex_unlock(&monitor.mutex);
    return -1;
}

int add_protocol(const char* name, int level) {
    pthread_mutex_lock(&monitor.mutex);
    if (monitor.count >= MAX_PROTOCOLS) {
        pthread_mutex_unlock(&monitor.mutex);
        return -1;
    }
    
    int idx = monitor.count++;
    strncpy(monitor.protocols[idx].name, name, MAX_NAME_LEN - 1);
    monitor.protocols[idx].name[MAX_NAME_LEN - 1] = '\0';
    monitor.protocols[idx].frames = 0;
    monitor.protocols[idx].bytes = 0;
    monitor.protocols[idx].last_frames = 0;
    monitor.protocols[idx].last_bytes = 0;
    monitor.protocols[idx].rate_frames = 0;
    monitor.protocols[idx].rate_bytes = 0;
    monitor.protocols[idx].level = level;
    
    pthread_mutex_unlock(&monitor.mutex);
    return idx;
}

void update_protocol(const char* name, unsigned long packet_size, int level) {
    int idx = find_protocol(name);
    if (idx == -1) {
        idx = add_protocol(name, level);
        if (idx == -1) return;
    }
    
    pthread_mutex_lock(&monitor.mutex);
    monitor.protocols[idx].frames++;
    monitor.protocols[idx].bytes += packet_size;
    pthread_mutex_unlock(&monitor.mutex);
}

void parse_packet(unsigned char* buffer, int size) {
    struct ethhdr* eth_header = (struct ethhdr*)buffer;
    unsigned short eth_type = ntohs(eth_header->h_proto);
    
    update_protocol("eth", size, 0);
    
    if (eth_type == ETH_P_IP) {
        struct iphdr* ip_header = (struct iphdr*)(buffer + sizeof(struct ethhdr));
        update_protocol("ip", size, 1);
        
        if (ip_header->protocol == IPPROTO_TCP) {
            update_protocol("tcp", size, 2);
            
            struct tcphdr* tcp_header = (struct tcphdr*)(buffer + sizeof(struct ethhdr) + sizeof(struct iphdr));
            unsigned short src_port = ntohs(tcp_header->source);
            unsigned short dst_port = ntohs(tcp_header->dest);
            
            if (src_port == 80 || dst_port == 80) {
                update_protocol("http", size, 3);
            } else if (src_port == 443 || dst_port == 443) {
                update_protocol("tls", size, 3);
            } else if (src_port == 22 || dst_port == 22) {
                update_protocol("ssh", size, 3);
            } else if (src_port == 21 || dst_port == 21) {
                update_protocol("ftp", size, 3);
            }
            
        } else if (ip_header->protocol == IPPROTO_UDP) {
            update_protocol("udp", size, 2);
            
            struct udphdr* udp_header = (struct udphdr*)(buffer + sizeof(struct ethhdr) + sizeof(struct iphdr));
            unsigned short src_port = ntohs(udp_header->source);
            unsigned short dst_port = ntohs(udp_header->dest);
            
            if (src_port == 53 || dst_port == 53) {
                update_protocol("dns", size, 3);
            } else if (src_port == 67 || dst_port == 67 || src_port == 68 || dst_port == 68) {
                update_protocol("dhcp", size, 3);
            } else if (src_port == 123 || dst_port == 123) {
                update_protocol("ntp", size, 3);
            } else if (src_port == 5353 || dst_port == 5353) {
                update_protocol("mdns", size, 3);
            } else if (dst_port >= 443 && dst_port <= 444) {
                update_protocol("quic", size, 3);
            }
            
        } else if (ip_header->protocol == IPPROTO_ICMP) {
            update_protocol("icmp", size, 2);
        }
    } else if (eth_type == ETH_P_ARP) {
        update_protocol("arp", size, 1);
    } else if (eth_type == ETH_P_IPV6) {
        update_protocol("ipv6", size, 1);
        update_protocol("icmpv6", size, 2);  // Simplified - assume ICMPv6
    }
}

void* packet_capture_thread(void* arg) {
    int sock_fd;
    unsigned char buffer[BUFFER_SIZE];
    struct sockaddr_ll sll;
    socklen_t sll_len = sizeof(sll);
    
    // Create raw socket
    sock_fd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sock_fd < 0) {
        perror("socket");
        monitor.running = 0;
        return NULL;
    }
    
    // Bind to specific interface if specified
    if (strlen(monitor.interface) > 0) {
        struct ifreq ifr;
        memset(&ifr, 0, sizeof(ifr));
        strncpy(ifr.ifr_name, monitor.interface, IFNAMSIZ - 1);
        
        if (setsockopt(sock_fd, SOL_SOCKET, SO_BINDTODEVICE, &ifr, sizeof(ifr)) < 0) {
            perror("setsockopt SO_BINDTODEVICE");
        }
    }
    
    while (monitor.running) {
        int packet_size = recvfrom(sock_fd, buffer, BUFFER_SIZE, 0, 
                                  (struct sockaddr*)&sll, &sll_len);
        
        if (packet_size > 0) {
            parse_packet(buffer, packet_size);
        } else if (packet_size < 0) {
            if (monitor.running) {
                perror("recvfrom");
            }
            break;
        }
    }
    
    close(sock_fd);
    return NULL;
}

void calculate_rates() {
    pthread_mutex_lock(&monitor.mutex);
    
    for (int i = 0; i < monitor.count; i++) {
        protocol_stats_t* p = &monitor.protocols[i];
        
        p->rate_frames = p->frames - p->last_frames;
        p->rate_bytes = p->bytes - p->last_bytes;
        
        p->last_frames = p->frames;
        p->last_bytes = p->bytes;
    }
    
    pthread_mutex_unlock(&monitor.mutex);
}

int compare_protocols(const void* a, const void* b) {
    const protocol_stats_t* pa = (const protocol_stats_t*)a;
    const protocol_stats_t* pb = (const protocol_stats_t*)b;
    
    // Sort by bytes in descending order
    if (pb->bytes > pa->bytes) return 1;
    if (pb->bytes < pa->bytes) return -1;
    
    // If bytes are equal, sort by frames
    if (pb->frames > pa->frames) return 1;
    if (pb->frames < pa->frames) return -1;
    
    return 0;
}

void display_stats() {
    clear_screen();
    
    time_t now = time(NULL);
    struct tm* tm_info = localtime(&now);
    char time_str[32];
    strftime(time_str, sizeof(time_str), "%H:%M:%S", tm_info);
    
    printf("Real-time Protocol Hierarchy Monitor - Interface: %s - %s\n", 
           strlen(monitor.interface) ? monitor.interface : "all", time_str);
    printf("================================================================================\n");
    printf("%-30s %10s %12s %10s %12s\n", 
           "PROTOCOL", "FRAMES", "BYTES", "RATE(F/s)", "RATE(B/s)");
    printf("================================================================================\n");
    
    // Create a copy for sorting
    protocol_stats_t sorted_protocols[MAX_PROTOCOLS];
    int display_count = 0;
    
    pthread_mutex_lock(&monitor.mutex);
    
    for (int i = 0; i < monitor.count; i++) {
        if (monitor.protocols[i].bytes > 0) {
            sorted_protocols[display_count++] = monitor.protocols[i];
        }
    }
    
    pthread_mutex_unlock(&monitor.mutex);
    
    // Sort protocols by bytes (descending)
    qsort(sorted_protocols, display_count, sizeof(protocol_stats_t), compare_protocols);
    
    unsigned long total_frames = 0, total_bytes = 0;
    
    for (int i = 0; i < display_count; i++) {
        protocol_stats_t* p = &sorted_protocols[i];
        char bytes_str[16], rate_bytes_str[16];
        char indent[32] = "";
        
        // Create indentation based on protocol level
        for (int j = 0; j < p->level && j < 10; j++) {
            strcat(indent, "  ");
        }
        
        bytes_to_human(p->bytes, bytes_str);
        bytes_to_human((unsigned long)p->rate_bytes, rate_bytes_str);
        
        printf("%s%-30s %10lu %12s %10.1f %12s\n",
               indent, p->name, p->frames, bytes_str, p->rate_frames, rate_bytes_str);
        
        if (p->level == 0) {  // Count only top-level protocols for total
            total_frames += p->frames;
            total_bytes += p->bytes;
        }
    }
    
    char total_bytes_str[16];
    bytes_to_human(total_bytes, total_bytes_str);
    
    printf("================================================================================\n");
    printf("TOTAL: %lu frames, %s\n", total_frames, total_bytes_str);
    printf("\nPress Ctrl+C to exit\n");
}

void print_usage(const char* prog_name) {
    printf("Usage: %s [-i interface] [-t interval]\n", prog_name);
    printf("Options:\n");
    printf("  -i interface  Network interface to monitor (default: all)\n");
    printf("  -t interval   Update interval in seconds (default: 1)\n");
    printf("  -h            Show this help message\n");
    printf("\nNote: This program requires root privileges to capture packets.\n");
}

int main(int argc, char* argv[]) {
    int update_interval = 1;
    int opt;
    
    // Parse command line arguments
    while ((opt = getopt(argc, argv, "i:t:h")) != -1) {
        switch (opt) {
            case 'i':
                strncpy(monitor.interface, optarg, sizeof(monitor.interface) - 1);
                monitor.interface[sizeof(monitor.interface) - 1] = '\0';
                break;
            case 't':
                update_interval = atoi(optarg);
                if (update_interval < 1) update_interval = 1;
                break;
            case 'h':
                print_usage(argv[0]);
                return 0;
            default:
                print_usage(argv[0]);
                return 1;
        }
    }
    
    // Check if running as root
    if (geteuid() != 0) {
        fprintf(stderr, "This program requires root privileges to capture packets.\n");
        fprintf(stderr, "Please run as root: sudo %s\n", argv[0]);
        return 1;
    }
    
    // Initialize monitor
    monitor.running = 1;
    monitor.count = 0;
    pthread_mutex_init(&monitor.mutex, NULL);
    
    // Set up signal handler
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    printf("Starting protocol hierarchy monitor...\n");
    if (strlen(monitor.interface) > 0) {
        printf("Monitoring interface: %s\n", monitor.interface);
    } else {
        printf("Monitoring all interfaces\n");
    }
    printf("Update interval: %d second(s)\n", update_interval);
    printf("Initializing capture...\n\n");
    
    // Start packet capture thread
    pthread_t capture_thread;
    if (pthread_create(&capture_thread, NULL, packet_capture_thread, NULL) != 0) {
        perror("pthread_create");
        return 1;
    }
    
    // Main display loop
    while (monitor.running) {
        sleep(update_interval);
        calculate_rates();
        display_stats();
    }
    
    // Cleanup
    pthread_join(capture_thread, NULL);
    pthread_mutex_destroy(&monitor.mutex);
    
    return 0;
}
