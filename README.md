# MAC Address Spoofing

MAC address spoofing is a method that changes the unique identifier, known as the Media Access Control (MAC) address, assigned to a network interface controller (NIC) on a device. Each NIC has a MAC address assigned by the manufacturer, which uniquely identifies the device on a network. By changing the MAC address, users can hide their actual identity on the network, enabling anonymous operation or bypassing network restrictions. This can be achieved either through specific software or by manually adjusting the device's network settings.

## Further Reading
- [General technical knowledge](https://wikipedia.org/wiki/MAC_address)
- [Differences between CurrentControlSet, ControlSet001, and ControlSet002](https://stackoverflow.com/questions/291519/how-does-currentcontrolset-differ-from-controlset001-and-controlset002)
- [Issues with Windows 7 Wireless NIC & Workaround](https://blog.technitium.com/2011/05/tmac-issue-with-wireless-network.html)

## Important Note on Windows Registry
In the Windows Registry, the key `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}` is crucial for managing and storing network adapter information. Each subkey within this class corresponds to a specific network adapter installed on the system.

- **Class Identifier (CLSID)**: `{4d36e972-e325-11ce-bfc1-08002be10318}` is a Class Identifier (CLSID) associated with the "Network Adapters" class in the Windows Device Manager.
- **Subkeys and Indices**: Under this class key, you'll find subkeys with numerical indices, each representing a different network adapter. For example, `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000` represents the first network adapter.
- **Key Values**: 
  - `NetCfgInstanceId`: Contains a unique identifier for the network adapter.
  - `DriverDesc`: Provides a human-readable description or name of the network adapter.
  - `NetworkAddress`: Stores the MAC address of the network adapter.

## Visual Guides
Retrieving & displaying captions from NICs:
![Retrieving & displaying captions from NICs](https://github.com/Scrut1ny/Windows-MAC-Address-Spoofer/assets/53458032/982813d4-da4d-4631-84c6-f9480c1dcff9)

Showing registry subkeys (aka Indexes from a Caption) under the CLSID:
![Showing registry subkeys under the CLSID](https://github.com/Scrut1ny/Windows-MAC-Address-Spoofer/assets/53458032/02dc8ed8-1bd9-43d4-8cd1-464da63a5b43)
