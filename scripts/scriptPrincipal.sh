#!/bin/bash

# Directorio base de las configuraciones.
BASE_DIR="/home/alumno/practicaRed"

# Scripts de generación de XML.
REDES_SCRIPT="${BASE_DIR}/script1.py"
MAQUINAS_SCRIPT="${BASE_DIR}/script2.py"

# Redes a configurar.
NETWORKS=("red1" "red2" "red3" "red4" "red5" "red6")

# Máquinas virtuales a configurar.
VMS=("pc1" "pc2" "pc3" "pc4" "server" "r1" "r2" "r3" "r4")

# Función para manejar errores.
handle_error() {
    echo "Error: $1"
    exit 1
}

# Función para crear archivos de interfaces.
crear_archivos_interfaces() {
    echo "Creando archivos de interfaces para cada máquina..."
    
    # Configuración para PCs y servidor
    declare -A configs
    configs["pc1"]="10.0.0.2/24 10.0.0.1"
    configs["pc2"]="10.0.1.2/24 10.0.1.1"
    configs["pc3"]="10.0.2.2/24 10.0.2.1"
    configs["pc4"]="10.0.3.2/24 10.0.3.1"
    configs["server"]="10.0.4.2/24 10.0.4.1"

    # Crear directorio temporal para los archivos de configuración.
    TEMP_DIR="${BASE_DIR}/network_configs"
    mkdir -p "${TEMP_DIR}"

    # Crear archivos de netplan para PCs y servidor.
    for vm in "${!configs[@]}"; do
        IFS=' ' read -ra CONFIG <<< "${configs[$vm]}"
        IP=${CONFIG[0]}
        GATEWAY=${CONFIG[1]}
        
        mkdir -p "${TEMP_DIR}/${vm}"
        
        if [[ $vm == "server" ]]; then
            cat > "${TEMP_DIR}/${vm}/50-cloud-init.yaml" << EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses: [192.168.122.10/24]
      gateway4: 192.168.122.1
    eth1:
      addresses: [$IP]
      gateway4: $GATEWAY
EOF
        else
            cat > "${TEMP_DIR}/${vm}/50-cloud-init.yaml" << EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses: [$IP]
      gateway4: $GATEWAY
EOF
        fi
    done

    # Configuración para routers.
    declare -A router_configs
    router_configs["r1"]="eth1:10.0.0.1/24 eth2:10.0.1.1/24 eth3:172.16.0.1/29"
    router_configs["r2"]="eth1:172.16.0.2/29 eth2:172.16.0.3/29 eth3:172.16.0.5/29"
    router_configs["r3"]="eth1:10.0.2.1/24 eth2:10.0.3.1/24 eth3:172.16.0.4/29"
    router_configs["r4"]="eth1:172.16.0.6/29 eth2:10.0.4.1/24"

    # Crear archivos de netplan para routers.
    for router in "${!router_configs[@]}"; do
        mkdir -p "${TEMP_DIR}/${router}"
        
        # Crear configuración de netplan.
        echo "network:" > "${TEMP_DIR}/${router}/50-cloud-init.yaml"
        echo "  version: 2" >> "${TEMP_DIR}/${router}/50-cloud-init.yaml"
        echo "  ethernets:" >> "${TEMP_DIR}/${router}/50-cloud-init.yaml"
        
        for interface in ${router_configs[$router]}; do
            IFS=':' read -ra IF_CONFIG <<< "$interface"
            IFACE=${IF_CONFIG[0]}
            IP=${IF_CONFIG[1]}
            echo "    $IFACE:" >> "${TEMP_DIR}/${router}/50-cloud-init.yaml"
            echo "      addresses: [$IP]" >> "${TEMP_DIR}/${router}/50-cloud-init.yaml"
        done
        
        # Crear archivo de configuración FRR.
        mkdir -p "${TEMP_DIR}/${router}/frr"
        cat > "${TEMP_DIR}/${router}/daemons" << EOF
zebra=yes
ospfd=yes
bgpd=no
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
ldpd=no
nhrpd=no
eigrpd=no
babeld=no
sharpd=no
pbrd=no
bfdd=no
fabricd=no
vrrpd=no
pathd=no
EOF
    done
}

# Función para copiar archivos de configuración a las máquinas.
copiar_configuracion() {
    echo "Copiando archivos de configuración de red a las máquinas virtuales..."
    
    for vm in "${VMS[@]}"; do
        # Copiar configuración de red.
        sudo virt-copy-in -d "${vm}" "${TEMP_DIR}/${vm}/50-cloud-init.yaml" /etc/netplan/ || handle_error "No se pudo copiar la configuración de red para ${vm}"
        echo "Configuración de red copiada correctamente para ${vm}"
    done
}

# Generar archivos XML para redes y máquinas.
generar_xmls() {
    echo "Generando archivos XML para redes..."
    python3 "${REDES_SCRIPT}" || handle_error "Fallo en la generación de XMLs de redes"
    
    echo "Generando archivos XML para máquinas virtuales..."
    python3 "${MAQUINAS_SCRIPT}" || handle_error "Fallo en la generación de XMLs de máquinas virtuales"
}

# Configurar redes.
configurar_redes() {
    echo "Configurando redes..."
    for network in "${NETWORKS[@]}"; do
        sudo virsh net-define "${BASE_DIR}/${network}.xml" || handle_error "No se pudo definir la red ${network}"
        sudo virsh net-start "${network}" || handle_error "No se pudo iniciar la red ${network}"
        sudo virsh net-autostart "${network}" || handle_error "No se pudo establecer autostart para ${network}"
        echo "Red ${network} configurada correctamente"
    done
}

# Configurar máquinas virtuales.
configurar_maquinas() {
    echo "Configurando máquinas virtuales..."
    for vm in "${VMS[@]}"; do
        sudo virsh define "${BASE_DIR}/${vm}/${vm}.xml" || handle_error "No se pudo definir la máquina ${vm}"
        echo "Máquina virtual ${vm} definida correctamente"
    done
}

# Iniciar máquinas virtuales.
iniciar_maquinas() {
    echo "Iniciando máquinas virtuales..."
    for vm in "${VMS[@]}"; do
        sudo virsh start "${vm}" || handle_error "No se pudo iniciar la máquina ${vm}"
        echo "Máquina virtual ${vm} iniciada correctamente"
        
        # Si es un router, necesitamos instalar y configurar FRR.
        if [[ $vm == r* ]]; then
            echo "Configurando FRR en ${vm}..."
            # Primero instalamos FRR y habilitamos IP forwarding.
            expect -c "
            set timeout 240
            spawn sudo virsh console $vm
            sleep 2
            send \"\r\"
            expect \"agr login:\" { send \"root\r\" }
            expect \"Password:\" { send \"agr\r\" }
            expect \"root@agr:~#\" { send \"echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf\r\" }
            expect \"root@agr:~#\" { send \"sysctl -p\r\" }
            expect \"root@agr:~#\" { send \"apt-get update\r\" }
            expect \"root@agr:~#\" { send \"DEBIAN_FRONTEND=noninteractive apt-get install -y frr frr-doc\r\" }
            expect \"root@agr:~#\" {
                send \"echo 'zebra=yes\\nospfd=yes\\nbgpd=no\\nospf6d=no\\nripd=no\\nripngd=no\\nisisd=no\\npimd=no\\nldpd=no\\nnhrpd=no\\neighrpd=no\\nbabeld=no\\nsharpd=no\\npbrd=no\\nbfdd=no\\nfabricd=no\\nvrrpd=no\\npathd=no\\n' > /etc/frr/daemons\r\"
            }
            expect \"root@agr:~#\" { send \"chown frr:frr /etc/frr/daemons\r\" }
            expect \"root@agr:~#\" { send \"chmod 640 /etc/frr/daemons\r\" }
            expect \"root@agr:~#\" { send \"touch /etc/frr/frr.conf\r\" }
            expect \"root@agr:~#\" { send \"chown frr:frr /etc/frr/frr.conf\r\" }
            expect \"root@agr:~#\" { send \"chmod 640 /etc/frr/frr.conf\r\" }
            expect \"root@agr:~#\" { send \"systemctl restart frr\r\" }
            expect \"root@agr:~#\" { send \"systemctl enable frr\r\" }
            expect \"root@agr:~#\" { send \"exit\r\" }
            expect \"agr login:\" { send \"\x1d\"; }
            expect eof
            "
            
            sleep 5
            
            # Luego configuramos cada router específicamente.
            if [[ $vm == "r1" ]]; then
                expect -c "
                set timeout 240
                spawn sudo virsh console r1
                sleep 6
                send \"\r\"
                expect \"agr login:\" { send \"root\r\" }
                expect \"Password:\" { send \"agr\r\" }
                expect \"root@agr:~#\" {
                    send \"vtysh\r\"
                    expect \"#\" {
                        send \"configure terminal\r\"
                        send \"ip forwarding\r\"
                        send \"interface eth1\r\"
                        send \"ip address 10.0.0.1/24\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"interface eth2\r\"
                        send \"ip address 10.0.1.1/24\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"interface eth3\r\"
                        send \"ip address 172.16.0.1/29\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"router ospf\r\"
                        send \"network 10.0.0.0/24 area 0\r\"
                        send \"network 10.0.1.0/24 area 0\r\"
                        send \"network 172.16.0.0/29 area 0\r\"
                        send \"exit\r\"
                        send \"exit\r\"
                        send \"write memory\r\"
                        send \"exit\r\"
                    }
                }
                expect \"root@agr:~#\" { send \"exit\r\" }
                expect \"agr login:\" { send \"\x1d\"; }
                expect eof
                "
            elif [[ $vm == "r2" ]]; then
                expect -c "
                set timeout 240
                spawn sudo virsh console r2
                sleep 6
                send \"\r\"
                expect \"agr login:\" { send \"root\r\" }
                expect \"Password:\" { send \"agr\r\" }
                expect \"root@agr:~#\" {
                    send \"vtysh\r\"
                    expect \"#\" {
                        send \"configure terminal\r\"
                        send \"ip forwarding\r\"
                        send \"interface eth1\r\"
                        send \"ip address 172.16.0.2/29\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"interface eth2\r\"
                        send \"ip address 172.16.0.3/29\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"interface eth3\r\"
                        send \"ip address 172.16.0.5/29\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"router ospf\r\"
                        send \"network 172.16.0.0/29 area 0\r\"
                        send \"exit\r\"
                        send \"exit\r\"
                        send \"write memory\r\"
                        send \"exit\r\"
                    }
                }
                expect \"root@agr:~#\" { send \"exit\r\" }
                expect \"agr login:\" { send \"\x1d\"; }
                expect eof
                "
            elif [[ $vm == "r3" ]]; then
                expect -c "
                set timeout 240
                spawn sudo virsh console r3
                sleep 6
                send \"\r\"
                expect \"agr login:\" { send \"root\r\" }
                expect \"Password:\" { send \"agr\r\" }
                expect \"root@agr:~#\" {
                    send \"vtysh\r\"
                    expect \"#\" {
                        send \"configure terminal\r\"
                        send \"ip forwarding\r\"
                        send \"interface eth1\r\"
                        send \"ip address 10.0.2.1/24\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"interface eth2\r\"
                        send \"ip address 10.0.3.1/24\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"interface eth3\r\"
                        send \"ip address 172.16.0.4/29\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"router ospf\r\"
                        send \"network 10.0.2.0/24 area 0\r\"
                        send \"network 10.0.3.0/24 area 0\r\"
                        send \"network 172.16.0.0/29 area 0\r\"
                        send \"exit\r\"
                        send \"exit\r\"
                        send \"write memory\r\"
                        send \"exit\r\"
                    }
                }
                expect \"root@agr:~#\" { send \"exit\r\" }
                expect \"agr login:\" { send \"\x1d\"; }
                expect eof
                "
            elif [[ $vm == "r4" ]]; then
                expect -c "
                set timeout 2
                spawn
spawn sudo virsh console r4
                sleep 6
                send \"\r\"
                expect \"agr login:\" { send \"root\r\" }
                expect \"Password:\" { send \"agr\r\" }
                expect \"root@agr:~#\" {
                    send \"vtysh\r\"
                    expect \"#\" {
                        send \"configure terminal\r\"
                        send \"ip forwarding\r\"
                        send \"interface eth1\r\"
                        send \"ip address 172.16.0.6/29\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"interface eth2\r\"
                        send \"ip address 10.0.4.1/24\r\"
                        send \"no shutdown\r\"
                        send \"exit\r\"
                        send \"router ospf\r\"
                        send \"network 172.16.0.0/29 area 0\r\"
                        send \"network 10.0.4.0/24 area 0\r\"
                        send \"exit\r\"
                        send \"exit\r\"
                        send \"write memory\r\"
                        send \"exit\r\"
                    }
                }
                expect \"root@agr:~#\" { send \"exit\r\" }
                expect \"agr login:\" { send \"\x1d\"; }
                expect eof
                "
            fi
        else
            # Si no es router (es PC o servidor) y configuramos netplan.
            echo "Configurando red en ${vm}..."
            expect -c "
            set timeout 200
            spawn sudo virsh console $vm
            sleep 4
            send \"\r\"
            expect \"agr login:\" { send \"root\r\" }
            expect \"Password:\" { send \"agr\r\" }
            expect \"root@agr:~#\" { send \"netplan apply\r\" }
            expect \"root@agr:~#\" { send \"exit\r\" }
            expect \"agr login:\" { send \"\x1d\"; }
            expect eof
            "
        fi
        
        # Esperar un poco para asegurarse de que la máquina está completamente iniciada.
        sleep 15
    done
}

# Función para configurar servidor web.
configurar_servidor_web() {
    echo "Configurando servidor web..."
    
    expect -c "
    set timeout 300
    spawn sudo virsh console server
    sleep 4
    send \"\r\"
    expect \"agr login:\" { send \"root\r\" }
    expect \"Password:\" { send \"agr\r\" }
    expect \"root@agr:~#\" 
    send \"exit\r\"
    expect \"agr login:\" { send \"\x1d\"; }
    expect eof
    "
    
    #Aqui va la configuración del servidor como cada una quiera.
    
    echo "Servidor web configurado correctamente"
}

main() {
    echo "Script de configuración de redes y máquinas virtuales"
    
    generar_xmls
    configurar_redes
    configurar_maquinas
    crear_archivos_interfaces
    copiar_configuracion
    
    # Iniciar todas las máquinas (incluyendo routers y PCs).
    iniciar_maquinas
    
    configurar_servidor_web
    
    echo "Configuración completada exitosamente"
}

# Ejecutar el script.
main

