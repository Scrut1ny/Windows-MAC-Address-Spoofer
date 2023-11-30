
MAC address spoofing is a technique used to alter the unique identifier assigned to a network interface controller (NIC) on a device. Each NIC has a Media Access Control (MAC) address assigned by the manufacturer, which serves as a unique identifier for that device on a network. By altering the MAC address of a device, a user can effectively conceal their true identity on the network, allowing them to operate anonymously or circumvent network restrictions. This can be accomplished through the use of specialized software or manually by modifying the device's network settings.

Discoveries (links):
- General technical knowledge
  - https://wikipedia.org/wiki/MAC_address
- CurrentControlSet differences
  - https://stackoverflow.com/questions/291519/how-does-currentcontrolset-differ-from-controlset001-and-controlset002
  - https://superuser.com/questions/241426/what-are-the-differences-between-the-multiple-controlsets-in-the-windows-registr
- Issues With Wireless NIC & Workaround
  - https://blog.technitium.com/2011/05/tmac-issue-with-wireless-network.html

> [!IMPORTANT]
> In the Windows Registry, the key HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318} plays a vital role in managing and storing information related to network adapters. Each subkey within this class corresponds to a specific network adapter installed on the system.
>
> Class Identifier (CLSID):
> The {4d36e972-e325-11ce-bfc1-08002be10318} portion of the key is a Class Identifier (CLSID) associated with the "Network Adapters" class in the Windows Device Manager.
>
> Subkeys and Indices:
> Under this class key, you'll find subkeys with numerical indices, each representing a different network adapter. For example, HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000 represents the first network adapter.
>
> Key Values:
>    NetCfgInstanceId: Contains a unique identifier for the network adapter.
>    DriverDesc: Provides a human-readable description or name of the network adapter.
>    Service: Specifies the service name associated with the network adapter.
>    IPAddress and SubnetMask: Information related to the IP configuration of the network adapter.
>    ConnectionName: Represents the name of the network connection.
>    Device Parameters: Holds additional parameters and settings related to the network adapter's operation.
>    NetworkAddress: Stores the MAC address of the network adapter.

https://github.com/Scrut1ny/Windows-MAC-Address-Spoofer/assets/53458032/86b4c1e9-baec-4a6f-b78a-0b5c172c9dd6
