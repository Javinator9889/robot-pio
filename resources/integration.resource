*** Settings ***
Documentation       Contains utility keywords being used by the ``integration`` tests.

Resource            ${CURDIR}/comm.resource
Resource            ${CURDIR}/mqtt.resource
Resource            ${CURDIR}/pio.resource
Library             ${CURDIR}/WiFi.py
Library             Collections
Library             MQTTLibrary

Variables           ${CURDIR}/SensorData.py


*** Variables ***
${SSID}                 RobotFramework
${PASSWORD}             robotframework
${WIFI_NETWORK}         10.0.0.1
${DEVICE_IP}            10.0.0.2
${MQTT_HELLO_TOPIC}     hello
${MQTT_SERVER}          localhost
${MQTT_PORT}            1883


*** Keywords ***
Suite Setup
    [Documentation]    Sets up the suite. It starts the MQTT server and creates the serial session.
    ...    Loads the firmware to the device and performs the WiFi authentication.

    ${device}    Find Available Device
    VAR    ${device}    scope=SUITE
    Load Firmware    ${device}

    ${session}              Create Serial Session    ${device}
    VAR    ${session}    scope=SUITE

    Start MQTT Server
    Wait Until Keyword Succeeds
    ...                     1 minute
    ...                     1 second
    ...                     Connect
    ...                     ${MQTT_SERVER}
    ...                     ${MQTT_PORT}

    Set Access Point SSID    ${SSID}
    Set Access Point Password    ${PASSWORD}
    Set Access Point IP    ${WIFI_NETWORK}
    Start Access Point

    Board Connectivity Setup
    ...                     ${SSID}
    ...                     ${PASSWORD}
    ...                     ${WIFI_NETWORK}
    ...                     ${DEVICE_IP}

    Board MQTT Setup        ${MQTT_SERVER}      ${MQTT_PORT}    ${DEVICE_IP}

Suite Teardown
    [Documentation]    Tears down the suite. It closes the serial session and stops the MQTT server.

    Close Serial Session
    Stop MQTT Server

Board Connectivity Setup
    [Documentation]    Prepares the board for the test by setting the WiFi credentials.
    [Arguments]             ${ssid}                 ${password}     ${wifi_network}     ${ip}

    Wait Until Prompt
    Send Command            wifi set ssid ${ssid}
    Send Command            wifi set password ${password}
    Send Command            wifi set mode 1
    Send Command            wifi set gw ${wifi_network}
    Send Command            wifi set ip ${ip}
    Send Command            wifi connect

    Wait Until Device Connected    ${DEVICE_IP}     timeout=1 minute

Board MQTT Setup
    [Documentation]    Prepares the board for the test by setting the MQTT settings. Should
    ...    be run once the board is connected to the WiFi.
    [Arguments]             ${mqtt_host}    ${mqtt_port}    ${ip}

    Wait Until Prompt
    Send Command            mqtt set host ${mqtt_host}
    Send Command            mqtt set port ${mqtt_port}
    Send Command            mqtt start

    Subscribe And Validate    ${MQTT_HELLO_TOPIC}    1      Hello from ${ip}

Read ${Sensor} Data
    [Documentation]    Reads the data from the ${Sensor} sensor. If the sensor does not exist,
    ...    fails with an error. It validates the data read from the sensor has the correct
    ...    format. It also validates the data is within the expected range.
    ...
    ...    \${Sensor} can be any of:
    ...
    ...    - Temperature (Celsius)
    ...    - Humidity (Percentage)
    ...    - Noise (Decibels)
    ...    - Light (Lux)
    ...
    ...    Returns the data read from the sensor as a number.

    Dictionary Should Contain Key
    ...         ${SENSORS}
    ...         ${Sensor.lower()}
    ...         Invalid sensor "${Sensor}"

    VAR    ${real}    ${SENSORS["${Sensor.lower()}"]}
    VAR    ${unit}    ${UNITS["${real}"]}

    Log         Reading ${Sensor} sensor data
    ${read}     Send Command            sensor read ${real}

    # https://regex101.com/r/pVMPsq/1
    ${match}    ${data}                 Should Match Regexp
    ...         ${read}
    ...         (-?[1-9]\\d*(?:\\.\\d+)?)(?:${unit})
    ...         Sensor reading failed
    ...         flags=IGNORECASE | MULTILINE

    ${data}     Convert To Number       ${data}
    VAR    ${range}    ${RANGES["${real}"]}

    IF    not $range[0] < ${data} <= $range[1]
        Fail    Sensor reading out of range: ${data} not in ${range}
    END

    RETURN    ${data}

Write ${Data} To ${Sensor} Sensor
    [Documentation]    Writes the ${Data} to the ${Sensor} sensor. If the sensor does not exist,
    ...    fails with an error. It does not validate the data written to the sensor, as it expects
    ...    the board to validate it.
    ...
    ...    \${Sensor} can be any of:
    ...
    ...    - Temperature (Celsius)
    ...    - Humidity (Percentage)
    ...    - Noise (Decibels)
    ...    - Light (Lux)

    Dictionary Should Contain Key
    ...             ${SENSORS}
    ...             ${sensor.lower()}
    ...             Invalid sensor "${sensor}"

    VAR    ${real}    ${SENSORS["${sensor.lower()}"]}
    ${Data}         Convert To Number       ${Data}

    Send Command    sensor write ${real} ${Data}

Restore Sensors
    [Documentation]    Invalidates any written data to the sensors. On the next read, the
    ...    sensors should return the correct data and not the written one.

    FOR    ${sensor}    IN    @{SENSORS}
        Send Command    sensor reset ${SENSORS["${sensor}"]}
    END
