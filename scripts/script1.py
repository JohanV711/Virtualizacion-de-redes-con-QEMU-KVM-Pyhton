import os
import xml.etree.ElementTree as ET

def crear_red_xml(nombre, direccion_red, netmask='255.255.255.0', bridge_num=None):
    """
    Generar configuración XML para una red de libvirt

    :param nombre: Nombre de la red (ej. 'red1')
    :param direccion_red: Dirección de red base (ej. '10.0.0.0')
    :param netmask: Máscara de red (por defecto 255.255.255.0)
    :param bridge_num: Número de bridge (si es None, se genera automáticamente)
    """
    # Crear el elemento raíz network.
    network = ET.Element('network')

    # Añadir nombre de la red.
    ET.SubElement(network, 'name').text = nombre

    # Configurar bridge.
    if bridge_num is None:
        bridge_num = int(nombre[3:])  # Extraer número de 'red1' -> 1
    bridge = ET.SubElement(network, 'bridge', name=f'virbr{bridge_num}')

    # Configurar IP.
    ip = ET.SubElement(network, 'ip', address=direccion_red, netmask=netmask)

    # Configurar DHCP.
    dhcp = ET.SubElement(ip, 'dhcp')

    if netmask == '255.255.255.248':  # Caso específico para subred /29
        dhcp_start = f'{".".join(direccion_red.split(".")[:-1])}.1'
        dhcp_end = f'{".".join(direccion_red.split(".")[:-1])}.6'
    else:
        # Rango genérico para otras redes.
        dhcp_start = f'{".".join(direccion_red.split(".")[:-1])}.2'
        dhcp_end = f'{".".join(direccion_red.split(".")[:-1])}.254'

    ET.SubElement(dhcp, 'range', start=dhcp_start, end=dhcp_end)


    return network

def main():
    # Directorio de trabajo.
    ruta_base = '/home/alumno/practicaRed'

    # Configuraciones de redes.
    redes = [
        {'nombre': 'red1', 'direccion': '10.0.0.0'},
        {'nombre': 'red2', 'direccion': '10.0.1.0'},
        {'nombre': 'red3', 'direccion': '10.0.2.0'},
        {'nombre': 'red4', 'direccion': '10.0.3.0'},
        {'nombre': 'red5', 'direccion': '10.0.4.0'},
        {'nombre': 'red6', 'direccion': '172.16.0.0', 'netmask': '255.255.255.248'}
    ]

    # Crear directorio si no existe.
    os.makedirs(ruta_base, exist_ok=True)

    # Generar XML para cada red.
    for i, red in enumerate(redes, 1):
        # Crear árbol XML.
        red_xml = crear_red_xml(
            red['nombre'],
            red['direccion'],
            red.get('netmask', '255.255.255.0'),
            i
        )

        # Crear árbol.
        tree = ET.ElementTree(red_xml)

        # Generar nombre de archivo.
        filename = os.path.join(ruta_base, f'{red["nombre"]}.xml')

        # Guardar XML.
        tree.write(filename, encoding='utf-8', xml_declaration=True)
        print(f"Generado archivo de red: {filename}")

if __name__ == "__main__":
    main()
