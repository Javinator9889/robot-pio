*** Settings ***
Documentation       Checks that the events are correctly triggered in the board. The events occur
...                 when a sensor reads a value above a certain threshold. The board sends the data to the
...                 MQTT host, which then triggers an event.

Resource            ${EXECDIR}/resources/integration.resource

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown
Test Teardown       Restore Sensors

Test Tags           event


*** Variables ***
&{THRESHOLDS}       temperature=30    humidity=70    noise=80    light=500
${EVENTS_TOPIC}     events/
${EVENTS_QOS}       1


*** Test Cases ***
Trigger Events
    [Documentation]    Validates that the noise event is triggered when the noise sensor reads a
    ...    value above the threshold.
    [Template]      Simulate Event Template

    FOR    ${sensor}    IN    @{THRESHOLDS}
        ${sensor}       ${THRESHOLDS[${sensor}]}
    END

People In The Room
    [Documentation]    Verifies that an increase in the light sensor triggers the
    ...    "people in the room" event.
    [Tags]      light

    Write 600 To Light Sensor
    Subscribe And Validate              ${EVENTS_TOPIC}room_occupied        ${EVENTS_QOS}    1

High Occupancy
    [Documentation]    Verifies that writing values to different sensors trigger the
    ...    "high occupancy" event. This event is triggered when the temperature, humidity,
    ...    noise, and light sensors read values above the threshold in different combinations.
    ...
    ...    For example, if the temperature and humidity sensors read values above the threshold,
    ...    the event is triggered. The same happens if the noise and light sensors read values
    ...    above the threshold.
    [Template]          High Occupancy Template

    temperature=31      humidity=71
    noise=81            light=501
    temperature=27      noise=70


*** Keywords ***
Simulate Event Template
    [Documentation]    Simulates an event by writing a value to the sensor.
    [Arguments]     ${sensor}       ${value}

    Write ${value} To ${sensor} Sensor
    Subscribe And Validate    ${EVENTS_TOPIC}${sensor}      ${EVENTS_QOS}    1

    [Teardown]      Restore ${sensor} Sensor

High Occupancy Template
    [Documentation]    Verifies that writing values to different sensors trigger the
    ...    "high occupancy" event.
    [Arguments]     &{sensors}

    FOR    ${sensor}    ${value}    IN    &{sensors}
        Write ${value} To ${sensor} Sensor
    END

    Subscribe And Validate    ${EVENTS_TOPIC}high_occupancy    ${EVENTS_QOS}    1

    [Teardown]              Restore Sensors
