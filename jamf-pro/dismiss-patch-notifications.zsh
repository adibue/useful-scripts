#!/bin/zsh

# Basics
clear
declare -i CURRENT=0

# Get JSS URL from plist
JSS_URL=$(plutil -extract jss_url raw "/Library/Preferences/com.jamfsoftware.jamf.plist")

## MARK: Functions
# Welcome message
function print_header() {
    echo
    echo "-----------------------------------------"
    echo "  Welcome to the Jamf Pro"
    echo "  patch notification dismissal automator!"
    echo 
    echo "  This script will help you to dismiss"
    echo "  patch notifications in your Jamf Pro"
    echo "  instance."
    echo
    echo "  Press any key to continue..."
    echo "-----------------------------------------"
    echo
    read -n 1
    clear
}

# Make user validate JSS_URL
function validate_url() {
    echo "I found this Jamf Pro URL: \e[1m\e[4m$JSS_URL\e[0m"
    echo
    printf "Is this correct? [Y/n]: "
    read -r response
    # Loop until user answers "y", "n", or presses enter
    until [[ "$response" =~ ^[YyNn]$ || -z "$response" ]]; do
        echo
        echo "I didn't get that."
        echo "Jamf Pro URL is set to: \e[1m\e[4m$JSS_URL\e[0m"
        printf "Is this correct? [Y/n]: "
        read -r response
    done
    # If the answer is no, invoke instance_prompt
    if [[ "$response" =~ ^[Nn]$ ]]; then
        clear
        echo "OK, let's set up your instance, then."
        instance_prompt
    fi
}

# Ask user for instance name
function instance_prompt() {
    echo
    echo "Please enter your Jamf Pro instance name (without "https://" and "jamfcloud.com")."
    echo "Example: If your Jamf Pro URL is https://myinstance.jamfcloud.com, enter 'myinstance.'"
    read "JSS_INSTANCE?Instance name: "
    echo
    JSS_URL="https://$JSS_INSTANCE.jamfcloud.com/"
    # Validate input
    until [[ "$JSS_INSTANCE" =~ ^[A-Za-z0-9-]+$ ]]; do
        echo
        echo "Got \e[1m\e[4m$JSS_URL\e[0m"
        echo "That doesn't look right... Let's try again."
        echo "Please enter \e[1mONLY\e[0m your Jamf Pro instance name (without "https://" and "jamfcloud.com")."
        read "JSS_INSTANCE?Instance name: "
        JSS_URL="https://$JSS_INSTANCE.jamfcloud.com/"
        echo
    done
    # Validate URL
    validate_url
    clear
}

# Credentials prompt
function credentials_prompt() {
    echo
    echo "Please enter your Jamf Pro credentials."
    echo "Don't worry, we're not storing them anywhere."
    echo
    read "username?Please enter your username: "
    # Check if username is empty
    until [[ -n "$username" ]]; do
        echo
        echo "\e[31mUsername can't be empty.\e[0m Please try again."
        read "username?Please enter your username: "
    done
    read -s "password?Please enter your password: "
    # Check if password is empty
    until [[ -n "$password" ]]; do
        echo
        echo "\e[31mPassword can't be empty.\e[0m Please try again."
        read -s "password?Please enter your password: "
    done
    echo
}

# Generate bearer token
function generate_token() {
    TOKEN=$(curl --request POST \
            --silent \
            --url "$JSS_URL/api/v1/auth/token" \
            --header 'accept: application/json' \
            --header 'authorization: Basic '$(echo -n "$username:$password" | base64)'' | \
            plutil -extract token raw - )
    # Validate token
    if [[ -z "$TOKEN" ]]; then
        echo
        echo "Uh-oh! Something went wrong while trying to generate a token."
        echo "Please double-check your credentials and try again."
        echo "\e[31mExiting...\e[0m"
        exit 1
    fi
}

# Progress bar
progress_bar() {
    local progress=$1
    local total=$2
    local width=50

    # Calculate percentage
    local percent=$(( progress * 100 / total ))
    local filled=$(( progress * width / total ))
    local empty=$(( width - filled ))

    # Define loading bar
    local bar=$(printf "%${filled}s" | tr " " "#")
    local spaces=$(printf "%${empty}s")

    # \r rewinds to the beginning of the line so it updates in place
    printf "\r[%-${width}s] %3d%% [%d/%d]" "${bar}${spaces}" "$percent" "$progress" "$total"
}

## MARK: Main script
# Print welcome message
print_header

# Check for an existing JSS_URL
if [[ -z "$JSS_URL" ]]; then
    echo
    echo "Looks like there's no Jamf Pro URL set on your machine."
    instance_prompt
    clear
else # Ask user to confirm JSS_URL
    validate_url
fi

clear
echo "Looks good! Moving on..."

# Prompt for credentials and generate token
credentials_prompt

clear
echo "Alright, trying to acquire a bearer token for"
echo "User: $username"
echo "Instance: $JSS_URL"
echo "..."
sleep 2
clear

generate_token

# Get list of notifications
NOTIF=$(curl --request GET \
    --silent \
    --url "$JSS_URL/api/v1/notifications" \
    --header 'accept: application/json' \
    --header "authorization: Bearer $TOKEN" )

# List how many notifications of type "PATCH_UPDATE" are found
declare -i NOTIF_COUNT=$(echo "$NOTIF" | jq '.[].type' | grep -o PATCH_UPDATE | wc -l )

if [[ "$NOTIF_COUNT" -eq 0 ]]; then
    echo "\e[42mCongratulations! There are no patch notifications to dismiss.\e[0m"
    echo "We're all done here."
    exit 0
else
    echo "I found $NOTIF_COUNT patch notification(s) of the type 'PATCH_UPDATE'."
    printf "Want to dismiss 'em all? [y/N]: "
    # Loop until user answers "y", "n", or presses enter
    read -r response

    until [[ "$response" =~ ^[YyNn]$ || -z "$response" ]]; do
        echo
        echo "I didn't get that."
        printf "Do you want to dismiss all $NOTIF_COUNT patch notification(s)? [y/N]: "
        read -r response
    done

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo
        echo "Dismissing all $NOTIF_COUNT patch notification(s)..."
        echo "This may take a moment..."
        echo

        # Loop through each notification ID and dismiss it
        echo "$NOTIF" | jq -r '.[] | select(.type=="PATCH_UPDATE") | .id' | while read -r ID; do
            ((CURRENT++))

            RESPONSE_CODE=$(curl --request DELETE \
                --silent \
                --write-out "%{http_code}" \
                --output /dev/null \
                --url "$JSS_URL/api/v1/notifications/PATCH_UPDATE/$ID" \
                --header 'accept: application/json' \
                --header "authorization: Bearer $TOKEN" )

            if [[ "$RESPONSE_CODE" -ne 204 ]]; then
                echo -e "\n❌ Failed to dismiss notification ID $ID. HTTP response code: $RESPONSE_CODE"
            fi

            progress_bar "$CURRENT" "$NOTIF_COUNT"
        done

        echo
        echo "\e[42mCleanup complete!\e[0m"
        echo "Time to say goodbye..."
        sleep 1
        exit 0

    else

        echo
        echo "You chose to hoard your notifications."
        echo "Time to say goodbye, then..."
        sleep 1
        exit 0
    fi
fi
