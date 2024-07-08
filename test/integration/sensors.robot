*** Settings ***
Documentation       Validates the different sensors available in the board. Checks that the returned
...                 data is the same as the one received in the MQTT host.

Resource            ${EXECDIR}/resources/integration.resource

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown
Test Teardown       Restore Sensors

Test Tags           sensor


*** Variables ***
@{INVALID_DATA}     1000    -1    200    -1
${TOPIC_BASE}       sensor/data/
${DEFAULT_QOS}      1


*** Test Cases ***
Verify All Board Sensors
    [Documentation]    Iterates over all the sensors available in the board and validates the data
    ...    returned by the sensor.
    [Template]      Validate Sensor Data

    FOR    ${sensor}    IN    @{SENSORS}
        ${sensor}
    END

Validate Wrong Sensor Data
    [Documentation]    Attempts to "force write" an invalid data to the board. Expects the board
    ...    to reject the data.
    [Template]      Write Invalid Sensor Data

    FOR    ${sensor}    ${data}    IN ZIP    ${SENSORS}    ${INVALID_DATA}
        ${sensor}       ${data}
    END


*** Keywords ***
Validate Sensor Data
    [Documentation]    Validates the data from the ${Sensor} sensor.
    ...
    ...    It reads the data from the sensor, sends it to the MQTT host, and checks that the data
    ...    is the same.
    ...
    ...    \${Sensor} can be any of:
    ...
    ...    - Temperature (Celsius)
    ...    - Humidity (Percentage)
    ...    - Noise (Decibels)
    ...    - Light (Lux)
    [Tags]          ${sensor}
    [Arguments]     ${sensor}

    VAR    ${real}    ${SENSORS["${sensor.lower()}"]}
    ${data}         Read ${sensor} Data

    Subscribe And Validate
    ...             ${TOPIC_BASE}${real}
    ...             ${DEFAULT_QOS}
    ...             ${data}

Write Invalid Sensor Data
    [Documentation]    Writes an invalid data to the board. Expects the board to reject the data.
    [Tags]          ${sensor}
    [Arguments]     ${sensor}       ${data}

    Run Keyword And Expect Error    *ERROR: Invalid data for ${sensor}*
    ...             Write ${data} To ${sensor} Sensor
