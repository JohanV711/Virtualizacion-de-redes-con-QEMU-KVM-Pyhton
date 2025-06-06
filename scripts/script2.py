import os
import sys
import shutil
import xml.etree.ElementTree as ET

def modificar_xml(vm_name, role):
    # Cargar la plantilla XML.
    tree = ET.parse('/home/alumno/practicaRed/plantilla-vm.xml')
    root = tree.getroot()

    # Crear directorio para la máquina virtual si no existe.
    vm_dir = f'/home/alumno/practicaRed/{vm_name}'
    os.makedirs(vm_dir, exist_ok=True)

    # Copiar imagen base.
    base_image = '/home/alumno/practicaRed/agr-vm-base.qcow2'
    vm_image = f'{vm_dir}/{vm_name}.qcow2'
    shutil.copy(base_image, vm_image)

    # Configurar el nombre de la VM.
    name_element = root.find('name')
    if name_element is not None:
        name_element.text = vm_name

    # Configurar el archivo de imagen de disco.
    disk_element = root.find(".//disk/source")
    if disk_element is not None:
        disk_element.set('file', vm_image)

    # Encontrar el elemento devices.
    devices_element = root.find('devices')

    # Eliminar todas las interfaces existentes.
    existing_interfaces = devices_element.findall('interface')
    for interface in existing_interfaces:
        devices_element.remove(interface)

    # Configuración específica según el rol.
    if role == "pc":
        # Mapear pc1 a red1, pc2 a red2, etc.
        network_name = f"red{int(vm_name[2:])}"
        interface = ET.Element('interface', type='network')
        ET.SubElement(interface, 'source', network=network_name)
        ET.SubElement(interface, 'model', type='virtio')

        # Encontrar el primer elemento antes de serial.
        serial_element = devices_element.find('serial')
        insert_index = list(devices_element).index(serial_element)
        devices_element.insert(insert_index, interface)

    elif role == "server":
        # Encontrar el primer elemento antes de serial.
        serial_element = devices_element.find('serial')
        insert_index = list(devices_element).index(serial_element)

        # Añadir interfaz NAT para routers.
        nat_interface = ET.Element('interface', type='bridge')
        ET.SubElement(nat_interface, 'source', bridge="virbr0")
        ET.SubElement(nat_interface, 'model', type='virtio')
        devices_element.insert(insert_index, nat_interface)

        # Servidor en red5.
        interface = ET.Element('interface', type='network')
        ET.SubElement(interface, 'source', network="red5")
        ET.SubElement(interface, 'model', type='virtio')
        devices_element.insert(insert_index, interface)

    elif role == "router":
        router_network_configs = {
            "r1": ["red6", "red2", "red1"],
            "r2": ["red6", "red6", "red6"],
            "r3": ["red6", "red4", "red3"],
            "r4": ["red5", "red6"]
        }

        # Encontrar el primer elemento antes de serial.
        serial_element = devices_element.find('serial')
        insert_index = list(devices_element).index(serial_element)

        # Añadir interfaces de red para el router.
        networks = router_network_configs.get(vm_name, [])
        for network in networks:
            interface = ET.Element('interface', type='network')
            ET.SubElement(interface, 'source', network=network)
            ET.SubElement(interface, 'model', type='virtio')
            devices_element.insert(insert_index, interface)

        # Añadir interfaz NAT para routers.
        nat_interface = ET.Element('interface', type='bridge')
        ET.SubElement(nat_interface, 'source', bridge="virbr0")
        ET.SubElement(nat_interface, 'model', type='virtio')
        devices_element.insert(insert_index, nat_interface)

    # Guardar el archivo XML modificado.
    output_filename = f'{vm_dir}/{vm_name}.xml'
    tree.write(output_filename, encoding="utf-8", xml_declaration=True)
    print(f"Archivo XML generado para {vm_name}: {output_filename}")

def main():
    # Configuración de máquinas virtuales.
    vms = [
        {"name": "pc1", "role": "pc"},
        {"name": "pc2", "role": "pc"},
        {"name": "pc3", "role": "pc"},
        {"name": "pc4", "role": "pc"},
        {"name": "server", "role": "server"},
        {"name": "r1", "role": "router"},
        {"name": "r2", "role": "router"},
        {"name": "r3", "role": "router"},
        {"name": "r4", "role": "router"}
    ]

    for vm in vms:
        modificar_xml(vm['name'], vm['role'])

if __name__ == "__main__":
    main()

