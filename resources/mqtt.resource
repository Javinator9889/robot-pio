*** Settings ***
Documentation       Resources for setting up and preparing a MQTT server for testing. It uses
...                 the Docker backend to create the MQTT server.

Library             Process


*** Variables ***
${IMAGE}            eclipse-mosquitto
${TAG}              2.0
@{MQTT_SERVER}      docker    run    --rm    -p    1883:1883    -p    9001:9001    ${IMAGE}:${TAG}
${ALIAS}            Mosquitto


*** Keywords ***
Start MQTT Server
    [Documentation]    Starts the MQTT server using Docker. It uses the image
    ...    ${IMAGE}:${TAG} and exposes the ports ``1883`` and ``9001``.
    ...
    ...    The server is started in the background and can be stopped with the
    ...    `Stop MQTT Server` keyword.
    ...
    ...    Returns the alias of the server, to be used with the `Process` library.
    Start Process       @{MQTT_SERVER}
    ...                 alias=${ALIAS}
    ...                 stderr=STDOUT

    Wait Until Keyword Succeeds    5 seconds    1 second        Process Should Be Running    Mosquitto

    RETURN              Mosquitto

Stop MQTT Server
    [Documentation]    Stops the MQTT server. It kills the process started by the
    ...    `Start MQTT Server` keyword.
    ...
    ...    Optionally, the alias of the server can be specified.
    [Arguments]             ${alias}=${ALIAS}
    Terminate Process       ${alias}
