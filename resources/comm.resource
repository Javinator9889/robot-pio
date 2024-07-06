*** Settings ***
Documentation       Communication against the board. Sends and receives data through the
...                 UART port.

Library             Process
Library             Telnet


*** Variables ***
${DEFAULT_PROCESS_TIMEOUT}      5 minutes
${TELNET_PORT}                  4444
${TELNET_HOST}                  localhost
${BAUDRATE}                     115200
${TELNET_PROMPT}                >
${CONNECTION_ALIAS}             Serial


*** Keywords ***
Create Serial Session
    [Documentation]    Creates a serial session to the board. It works by redirecting
    ...    the serial port through a network socket, then accessing it through telnet.
    ...    This looping is used to avoid the need for a physical serial port - this is,
    ...    allow remote debugging - as well as to use all the features of the telnet
    ...    library. See `Telnet` for more information.
    ...
    ...    Optionally, the baudrate, the telnet host and the telnet port can be specified. If
    ...    \${create_socatloop} is ${False}, assumes that the socat loop is already running.
    ...
    ...    Returns the alias of the connection, to be used with the `Telnet` library.
    [Arguments]
    ...                 ${port}
    ...                 ${baudrate}=${BAUDRATE}
    ...                 ${telnet_host}=${TELNET_HOST}
    ...                 ${telnet_port}=${TELNET_PORT}
    ...                 ${create_socatloop}=${True}

    IF    ${create_socatloop}
        ${handle}       Start Process       socat
        ...             TCP-LISTEN:${telnet_host}:${telnet_port},reuseaddr,fork
        ...             FILE:${port},b${baudrate}
        ...             stderr=STDOUT

        VAR    ${SOCATLOOP}    ${handle}    scope=TEST
    END

    Get Time

    Open Connection
    ...                 ${telnet_host}
    ...                 port=${telnet_port}
    ...                 alias=${CONNECTION_ALIAS}
    ...                 prompt=${TELNET_PROMPT}

    RETURN          ${CONNECTION_ALIAS}

Close Serial Session
    [Documentation]    Closes the serial session. It stops the socat loop and closes the
    ...    telnet connection.

    ${socat_process}        Get Variable Value      $SOCATLOOP      ${False}
    IF    ${socat_process}    Terminate Process    ${socat_process}

    Close Connection        ${CONNECTION_ALIAS}

Wait Until Prompt
    [Documentation]    Waits for the device until the prompt is reached. Sends an empty
    ...    character and looks for ${TELNET_PROMPT}.

    Send Command    ${EMPTY}

Send Command
    [Documentation]    Sends a command to the board and returns the response. A session
    ...    should have been created first with `Create Serial Session`.
    [Arguments]     ${command}

    ${ret}          Execute Command     ${command}      strip_prompt=${True}
    Should Not Match Regexp
    ...             ${ret}
    ...             (?im)^ERROR: .*$
    ...             Command "${command}" failed: ${ret}
    Should Not Match Regexp
    ...             ${ret}
    ...             (?im)^Exception \\(\d+\\):
    ...             Command "${command}" caused an exception
    RETURN          ${ret}
