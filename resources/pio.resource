*** Settings ***
Documentation       Interface to the PlatformIO Python library

Library             Process


*** Variables ***
@{CMD}                          python    -m    platformio
@{UPLOAD}                       run    -t    nobuild    -t    upload    --upload-port
${DEFAULT_PROCESS_TIMEOUT}      5 minutes


*** Keywords ***
Find Available Device
    [Documentation]    Queries the available devices connected to the system and
    ...    returns the port where it is attached. If more than one device is connected,
    ...    the index of the device to be used can be specified.
    [Arguments]             ${device_idx}=${0}

    ${ret}                  Run Process
    ...                     @{CMD}
    ...                     device
    ...                     list
    ...                     --json-output
    ...                     timeout=${DEFAULT_PROCESS_TIMEOUT}
    IF    ${ret.rc} != 0
        Log     ${ret.stderr}       level=ERROR
        Fail    Could not list devices (rc=${ret.rc}): ${ret.stderr}
    END

    ${devices}              Evaluate                json.loads($ret.stdout)    modules=json
    Should Not Be Empty     ${devices}              No devices found
    RETURN    ${devices[${device_idx}]["port"]}

Load Firmware
    [Documentation]    Loads the firmware to the device. The device should have been
    ...    previously identified by the `Find Available Device` keyword. The firmware
    ...    should have been previously compiled with ``pio run``.
    [Arguments]         ${port}

    ${upload_res}       Run Process
    ...                 @{CMD}
    ...                 @{UPLOAD}
    ...                 ${port}
    ...                 stderr=STDOUT
    ...                 timeout=${DEFAULT_PROCESS_TIMEOUT}
    IF    ${upload_res.rc} != 0
        Log     ${upload_res.stdout}    level=ERROR
        Fail    Firmware upload failed
    END
