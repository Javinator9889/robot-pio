from __future__ import annotations

from time import sleep

from PyAccessPoint.pyaccesspoint import AccessPoint
from robot.api.exceptions import Failure
from robot.running.timeouts import KeywordTimeout
from robot.utils.robottime import timestr_to_secs

_WAIT_FOR_DEVICE_CONNECTED = 30


class WiFi:
    """
    Provides methods and utilities to launch and manage a WiFi Access Point. It is built
    on top of the `PyAccessPoint` library, adapted to be used with Robot Framework.
    """

    def __init__(
        self,
        wlan="wlan0",
        inet=None,
        ip="192.168.45.1",
        netmask="255.255.255.0",
        ssid="MyAccessPoint",
        password="1234567890",
    ) -> None:
        self._ap = AccessPoint(wlan, inet, ip, netmask, ssid, password)

    def set_access_point_SSID(self, ssid: str) -> None:
        """Sets the SSID of the access point. Fails if the access point is already running.

        Args:
            ssid (:obj:`str`): The new SSID.

        Raises:
            :obj:`Failure`: If the access point is already running.
        """
        if self._ap.is_running():
            raise Failure("Cannot change SSID while the access point is running.")

        self._ap.ssid = ssid

    def set_access_point_password(self, password: str) -> None:
        """Sets the password of the access point. Fails if the access point is already running.

        Args:
            password (:obj:`str`): The new password.

        Raises:
            :obj:`Failure`: If the access point is already running.
        """
        if self._ap.is_running():
            raise Failure("Cannot change password while the access point is running.")

        self._ap.password = password

    def set_access_point_IP(self, ip: str) -> None:
        """Sets the IP of the access point. Fails if the access point is already running.

        Args:
            ip (:obj:`str`): The new IP.

        Raises:
            :obj:`Failure`: If the access point is already running.
        """
        if self._ap.is_running():
            raise Failure("Cannot change IP while the access point is running.")

        self._ap.ip = ip

    def start_access_point(self) -> None:
        """Starts the access point. Fails if the access point is already running.

        Raises:
            :obj:`Failure`: If the access point is already running.
        """
        if self._ap.is_running():
            raise Failure("The access point is already running.")

        self._ap.start()

    def stop_access_point(self) -> None:
        """Stops the access point. Fails if the access point is not running.

        Raises:
            :obj:`Failure`: If the access point is not running.
        """
        if not self._ap.is_running():
            raise Failure("The access point is not running.")

        self._ap.stop()

    def wait_until_device_connected(self, device: str, timeout: str = "30 seconds") -> None:
        """Waits until a device connects to the access point.

        Args:
            device (:obj:`str`): The device to wait for.
            timeout (:obj:`int`): The maximum time to wait, in seconds. Defaults to 30.

        Raises:
            :obj:`Failure`: If the device does not connect within the timeout.
        """
        # FIXME: We have no means (yet) to know when a device connects to the access point.
        # Simply wait `_WAIT_FOR_DEVICE_CONNECTED` seconds and hope for the best :)
        timeout_sec = timestr_to_secs(timeout)
        # sleep(_WAIT_FOR_DEVICE_CONNECTED)
