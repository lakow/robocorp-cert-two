*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.


Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Desktop
Library    RPA.Archive
Library    RPA.FileSystem
Library    RPA.RobotLogListener


*** Variables ***
${TEMP_DIRECTORY}=          ${OUTPUT_DIR}${/}Temp
${PDF_TEMP_DIRECTORY}=      ${TEMP_DIRECTORY}${/}pdf
${IMAGE_TEMP_DIRECTORY}=    ${TEMP_DIRECTORY}${/}image


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form   ${row}
        Wait Until Keyword Succeeds    10x    1s    Store the order
        ${pdf}=    Store the receipt as a PDF file            ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot      ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another Robot
    END
    Archive output pdfs
    [Teardown]    Close RobotSpareBin Browser and cleanup


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order


Get orders
    Create Directory    ${TEMP_DIRECTORY}

    ${filepath}=
    ...    Set Variable
    ...    ${TEMP_DIRECTORY}${/}orders.csv

    Download        https://robotsparebinindustries.com/orders.csv    ${filepath}    overwrite=True
    ${orders}=      Read table from CSV                               ${filepath}    header=True
    RETURN          ${orders}


Close the annoying modal
    Click Element When Visible    locator=xpath://*[@class='modal']//button[1]


Fill the form
    [Arguments]    ${row}

    Select From List By Value
    ...    head
    ...    ${row}[Head]

    Click Element    id-body-${row}[Body]
    Input Text       locator=xpath://input[@type="number"]    text=${row}[Legs]
    Input Text       address                                  ${row}[Address]
    Click Button     Preview


Store the order
    Click Button                   Order
    Mute Run On Failure            Page Should Contain Element
    Page Should Contain Element    id:receipt


Take a screenshot of the robot
    [Arguments]    ${order_number}

    ${path_screenshot}=
    ...    Set Variable
    ...    ${IMAGE_TEMP_DIRECTORY}${/}${order_number}.png

    Wait Until Element Is Visible    robot-preview-image

    Screenshot    robot-preview-image    ${path_screenshot}
    RETURN        ${path_screenshot}


Store the receipt as a PDF file
    [Arguments]     ${order_number}

    ${path_pdf}=
    ...    Set Variable
    ...    ${PDF_TEMP_DIRECTORY}${/}${order_number}.pdf

    Wait Until Element Is Visible    receipt

    ${order}=       Get Element Attribute    id:receipt    outerHTML
    Html To Pdf     ${order}                 ${path_pdf}
    RETURN          ${path_pdf}


Embed the robot screenshot to the receipt PDF file
    [Arguments]         ${screenshot}    ${pdf}
    ${files}=           Create List      ${screenshot}:align=center
    Open Pdf            ${pdf}
    Add Files To Pdf    ${files}         ${pdf}    ${True}
    Close Pdf           ${pdf}


Archive output pdfs
    ${zip_file_name}=
    ...    Set Variable    
    ...    ${OUTPUT_DIR}/orders.zip

    Archive Folder With Zip
    ...    ${PDF_TEMP_DIRECTORY}
    ...    ${zip_file_name}


Order another Robot
    Click Button    Order another robot


Close RobotSpareBin Browser and cleanup
    Close All Browsers
    Cleanup temporary PDF directory


Cleanup temporary PDF directory
    Remove Directory    ${TEMP_DIRECTORY}    ${True}