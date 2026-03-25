Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);' -Name WinAPI -Namespace WASP -PassThru | Out-Null
[WASP.WinAPI]::SendMessage(0xFFFF, 0x0112, 0xF170, 2)
