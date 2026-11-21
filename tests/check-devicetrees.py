"""Board wiring regressions, using the same DTBs as dtbs_check."""
from pathlib import Path
import subprocess
import sys


def get(dtb, node, prop, kind='s', optional=False):
    result = subprocess.run(['fdtget', '-t', kind, str(dtb), node, prop],
                            capture_output=True, text=True)
    if optional and result.returncode:
        return None
    result.check_returncode()
    value = result.stdout.strip()
    return [int(cell, 16) for cell in value.split()] if kind == 'x' else value


def check(directory):
    for board in ('j713', 'j773g'):
        dtb = Path(directory, f't8132-{board}.dtb')
        mini = board == 'j773g'
        assert get(dtb, '/', 'compatible').split()[0] == 'apple,' + board
        assert get(dtb, '/aliases', 'ethernet0', optional=True) == (
            '/soc/pcie@1cb0000000/pci@2,0/ethernet@0,0' if mini else None)
        for device in ('wifi@0,0', 'bluetooth@0,1'):
            node = '/soc/pcie@1cb0000000/pci@0,0/' + device
            assert get(dtb, node, 'brcm,board-type') == (
                'apple,sakhalin' if mini else 'apple,garden')

        for index, address in enumerate(('402', '40a', '412', '41a')):
            node = f'/soc/usb@{address}280000'
            status = get(dtb, node, 'status', optional=True) or 'okay'
            assert status == ('okay' if mini or index < 2 else 'disabled')
        if mini:
            assert get(dtb, '/soc/usb@412280000', 'dr_mode') == 'host'
            assert get(dtb, '/soc/usb@412280000', 'usb-role-switch', optional=True) is None
            assert get(dtb, '/soc/phy@413000000', 'apple,fixed-usb3') == ''
            assert get(dtb, '/soc/phy@413000000', 'apple,fixed-lane-swap') == ''
            assert get(dtb, '/soc/phy@413000000', 'orientation-switch', optional=True) is None
            irqs = get(dtb, '/soc/spmi@388908000/usb-pd@8', 'interrupts', 'x')
            assert irqs[::2] == [63, 65, 69, 71]
            mapping = get(dtb, '/soc/pcie@1cb0000000', 'iommu-map', 'x')
            dart0 = get(dtb, '/soc/iommu@490000000', 'phandle', 'x')[0]
            dart2 = get(dtb, '/soc/iommu@492000000', 'phandle', 'x')[0]
            assert mapping == [0x100, dart0, 1, 1, 0x200, dart2, 1, 1]
            dcp = '/soc/dcp@30ae00000'
            assert get(dtb, dcp, 'apple,connector-type') == 'HDMI-A'
            assert get(dtb, dcp, 'hdmi-pwren-gpios', 'x')[1:] == [15, 0]
            assert get(dtb, dcp, 'dp2hdmi-pwren-gpios', 'x')[1:] == [26, 0]
        else:
            assert get(dtb, '/soc/dcp@30ae00000/panel', 'compatible').startswith('apple,panel-j713 ')

        # Firmware-backed devices must stay disabled until m1n1 supplies state.
        for alias in ('gpu', 'pmp'):
            node = get(dtb, '/aliases', alias)
            assert get(dtb, node, 'status') == 'disabled'
        assert get(dtb, '/reserved-memory/gpu-firmware', 'status') == 'disabled'
        print(f'ok: {board} wiring and firmware handoff')


if __name__ == '__main__':
    check(sys.argv[1])
