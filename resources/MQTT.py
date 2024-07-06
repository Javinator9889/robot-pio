from __future__ import annotations

from paho.mqtt.client import Client, CallbackAPIVersion
from robot.api.exceptions import Failure
from robot.utils.robottime import parse_time

class MQTT:
    """
    Provides an abstraction layer over paho-mqtt library. It is built to be used with Robot Framework.
    """
    def __init__(self, host: str = "localhost", port: int = 1883, keepalive: str = "60s") -> None:
        self._mqtt = Client(CallbackAPIVersion.VERSION2)
        self._host = host
        self._port = port
        self._keepalive = parse_time(keepalive)

    def set_mqtt_host(self, host: str) -> None:
        """Sets the MQTT host.

        Args:
            host (:obj:`str`): The new MQTT host.

        Raises:
            :obj:`Failure`: If the client is connected.
        """
        if self._mqtt.is_connected():
            raise Failure("Cannot change host while the client is connected.")

        self._host = host

    def set_mqtt_port(self, port: int) -> None:
        """Sets the MQTT port.

        Args:
            port (:obj:`int`): The new MQTT port.

        Raises:
            :obj:`Failure`: If the client is connected.
        """
        if self._mqtt.is_connected():
            raise Failure("Cannot change port while the client is connected.")

        self._port = port

    def set_mqtt_keepalive(self, keepalive: str) -> None:
        """Sets the MQTT keepalive.

        Args:
            keepalive (:obj:`str`): The new MQTT keepalive.

        Raises:
            :obj:`Failure`: If the client is connected.
        """
        if self._mqtt.is_connected():
            raise Failure("Cannot change timeout while the client is connected.")

        self._keepalive = parse_time(keepalive)

    def mqtt_connect(self) -> None:
        """Connects to the MQTT broker.

        Raises:
            :obj:`Failure`: If the client is already connected.
        """
        if self._mqtt.is_connected():
            raise Failure("Client is already connected.")

        self._mqtt.connect(self._host, self._port, self._keepalive)
