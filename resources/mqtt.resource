*** Settings ***
Documentation       Resources for setting up and preparing a MQTT server for testing. It uses
...                 the Docker backend to create the MQTT server.

Library             Process


*** Variables ***
${IMAGE}                eclipse-mosquitto
${TAG}                  2.0
@{MQTT_SERVER_CMD}
...    docker
...    run
...    --rm
...    -p
...    1883:1883
...    -v
...    ${CURDIR}/mosquitto.conf:/mosquitto/config/mosquitto.conf
...    ${IMAGE}:${TAG}
${MQTT_ALIAS}           Mosquitto


*** Keywords ***
Start MQTT Server
    [Documentation]    Starts the MQTT server using Docker. It uses the image
    ...    ${IMAGE}:${TAG} and exposes the ports ``1883`` and ``9001``.
    ...
    ...    The server is started in the background and can be stopped with the
    ...    `Stop MQTT Server` keyword.
    ...
    ...    Returns the alias of the server, to be used with the `Process` library.
    Start Process       @{MQTT_SERVER_CMD}
    ...                 alias=${MQTT_ALIAS}
    ...                 stderr=STDOUT

    Wait Until Keyword Succeeds
    ...                 1 minute
    ...                 1 second
    ...                 MQTT Server Should Be Running

    RETURN              Mosquitto

Stop MQTT Server
    [Documentation]    Stops the MQTT server. It kills the process started by the
    ...    `Start MQTT Server` keyword.
    ...
    ...    Optionally, the alias of the server can be specified.
    [Arguments]             ${alias}=${MQTT_ALIAS}
    Terminate Process       ${alias}
    Wait For Process        ${alias}    timeout=1 minute
    ${rc}    Get Process Result      ${alias}
    Log    ${rc.stdout}

MQTT Server Should Be Running
    [Documentation]    Verifies that the MQTT server is running. It checks if the
    ...    process started by the `Start MQTT Server` keyword is still running.
    ...
    ...    Optionally, the alias of the server can be specified.
    [Arguments]     ${alias}=${MQTT_ALIAS}
    Process Should Be Running    ${alias}

    ${ret}          Run Process     nc      -z      localhost       1883
    Should Be Equal As Numbers    ${ret.rc}    0
