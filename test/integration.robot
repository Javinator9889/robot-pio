*** Settings ***
Documentation       Test suite to validate the communication between the board and the host. There
...                 are multiple tests available that validate whether the read data is the same as received
...                 in the MQTT host.
...
...                 The suite takes care of the setup and teardown of the MQTT server, the communication
...                 between the board and the host, and the firmware upload to the board.

Resource            ${EXECDIR}/resources/comm.resource
Resource            ${EXECDIR}/resources/mqtt.resource
Resource            ${EXECDIR}/resources/pio.resource
Library             ${EXECDIR}/resources/WiFi.py
Library             MQTTLibrary


*** Variables ***
${SSID}                 RobotFramework
${PASSWORD}             robotframework
${WIFI_NETWORK}         10.0.0.1
${DEVICE_IP}            10.0.0.2
${MQTT_HELLO_TOPIC}     hello
${MQTT_SERVER}          localhost
${MQTT_PORT}            1883


*** Test Cases ***
Validate Sensor Reading
    [Documentation]    Validates that the sensor reading is the same as the one received in the
    ...    MQTT host. It does so by reading the sensor data, sending it to the MQTT host, and
    ...    checking that the data is the same.
    ...
    ...    The test case uses the `Find Available Device`, `Load Firmware`, `Start MQTT Server`,
    ...    `Create Serial Session`, `Close Serial Session`, and `Stop MQTT Server` keywords.
    ...
    ...    The test case is successful if the data is the same, and it fails otherwise.
    [Tags]                  sensor                  reading
    ${port}                 Find Available Device
    Load Firmware           ${port}
    Start MQTT Server
    ${alias}                Create Serial Session    ${port}
    ...                     ${create_socatloop}=${False}
    ...                     ${telnet_host}=localhost
    ...                     ${telnet_port}=4444
    ...                     ${baudrate}=115200
    Close Serial Session
    Stop MQTT Server
    Should Be Equal         ${data}                 ${received_data}


*** Keywords ***
Suite Setup
    [Documentation]    Sets up the suite. It starts the MQTT server and creates the serial session.
    ...    Loads the firmware to the device and performs the WiFi authentication.

    ${device}               Find Available Device
    VAR    ${device}    scope=SUITE
    Load Firmware           ${device}

    ${session}              Create Serial Session    ${device}
    VAR    ${session}    scope=SUITE

    Start MQTT Server
    Connect                 ${MQTT_SERVER}      ${MQTT_PORT}

    Set Access Point SSID    ${SSID}
    Set Access Point Password    ${PASSWORD}
    Set Access Point IP     ${WIFI_NETWORK}
    Start Access Point

    Board Connectivity Setup
    ...                     ${SSID}
    ...                     ${PASSWORD}
    ...                     ${WIFI_NETWORK}
    ...                     ${DEVICE_IP}

    Board MQTT Setup        ${MQTT_SERVER}      ${MQTT_PORT}    ${DEVICE_IP}

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
