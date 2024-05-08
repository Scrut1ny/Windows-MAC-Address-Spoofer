# Windows MAC Address Spoofer

This is a Windows Batch script that allows you to manage the MAC addresses of your network interfaces. It provides options to spoof the MAC address with a random one, revert to the original MAC address, or set a custom MAC address. This script was inspired by the work of Scrut1ny.

## How it Works

1. **Check for Admin Rights:** The script first checks if it has administrator privileges, which are necessary for modifying network settings. If not, it requests for them.

2. **Selection Menu:** The script then enumerates all the Network Interface Controllers (NICs) on your system and displays them in a list. You can select the NIC you want to modify by entering its corresponding number.

3. **Action Menu:** After a NIC is selected, the script displays a list of actions you can perform: spoof the MAC address, revert to the original MAC address, or set a custom MAC address. You can select the action you want to perform by entering its corresponding number.

4. **Perform Action:** Depending on your selection, the script will perform the corresponding action:

   - **Spoof MAC:** The script generates a random MAC address and assigns it to the selected NIC.
   - **Revert to Original MAC:** The script removes the custom MAC address from the selected NIC, causing it to revert to its original MAC address.
   - **Set Custom MAC:** The script prompts you to enter a custom MAC address, which it then assigns to the selected NIC.

After performing the action, the script returns to the Selection Menu, allowing you to perform actions on other NICs or the same NIC again.

## Usage

To use this script, simply run it in a command prompt with administrator privileges. Follow the prompts to select a NIC and perform an action on it.

Please note that this script modifies system settings and should be used responsibly. Always ensure that you have the necessary permissions to modify network settings on your computer or network.

## Credits

This script was inspired by the work of [Scrut1ny](https://github.com/Scrut1ny).
