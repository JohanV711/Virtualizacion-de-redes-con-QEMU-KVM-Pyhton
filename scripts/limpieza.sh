#!/bin/bash

# Directorio base de las configuraciones.
BASE_DIR="/home/alumno/practicaRed"

# Redes a eliminar.
NETWORKS=("red1" "red2" "red3" "red4" "red5" "red6")

# Máquinas virtuales a eliminar.
VMS=("pc1" "pc2" "pc3" "pc4" "server" "r1" "r2" "r3" "r4")

# Función para manejar errores.
handle_error() {
    echo "Error: $1"
}

# Función para eliminar las redes.
eliminar_redes() {
    echo "Eliminando redes..."
    for network in "${NETWORKS[@]}"; do
        echo "Eliminando red ${network}..."
        
        # Intentar detener la red.
        sudo virsh net-destroy "${network}" 2>/dev/null || echo "La red ${network} ya estaba detenida"
        
        # Intentar eliminar la definición de la red.
        sudo virsh net-undefine "${network}" 2>/dev/null || echo "La red ${network} ya estaba indefinida"
        
        # Eliminar el archivo XML de la red.
        sudo rm -f "${BASE_DIR}/${network}.xml" 2>/dev/null
        
        echo "Red ${network} eliminada"
    done
}

# Función para eliminar las máquinas virtuales.
eliminar_maquinas() {
    echo "Eliminando máquinas virtuales..."
    for vm in "${VMS[@]}"; do
        echo "Eliminando máquina virtual ${vm}..."
        
        # Intentar detener la máquina virtual.
        sudo virsh destroy "${vm}" 2>/dev/null || echo "La máquina ${vm} ya estaba detenida"
        
        # Intentar eliminar la definición de la máquina virtual.
        sudo virsh undefine "${vm}" 2>/dev/null || echo "La máquina ${vm} ya estaba indefinida"
        
        # Eliminar el directorio de la máquina virtual.
        sudo rm -rf "${BASE_DIR}/${vm}" 2>/dev/null
        
        echo "Máquina virtual ${vm} eliminada"
    done
}

# Función para limpiar el directorio base.
limpiar_directorio() {
    echo "Limpiando directorio base..."
    
    # Eliminar todo el contenido del directorio base excepto la imagen base y la plantilla.
    find "${BASE_DIR}" -mindepth 1 -not -name 'agr-vm-base.qcow2' -not -name 'plantilla-vm.xml' -exec sudo rm -rf {} +
    
    echo "Directorio base limpiado"
}

# Función principal.
main() {
    echo "Iniciando limpieza de la infraestructura..."
    
    eliminar_maquinas
    eliminar_redes
    limpiar_directorio
    
    echo "Limpieza completada"
}

# Ejecutamos todo el script.
main