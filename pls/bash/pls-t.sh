#!/bin/bash -i

## MARK: Bootstrapping
# Source config library
source "./libs/config.shlib";

# Get user home directory and construct path to config file
USER_HOME=$(eval echo ~"${USER}")
CONFIG_PATH="${USER_HOME}/.config/pls-t"
CONFIG_FILE="${CONFIG_PATH}/pls-t.conf"

# Check if config file is already present
if [[ ! -f ${CONFIG_FILE} ]]; then
	config_exists=false
	echo "** CONFIG FILE MISSING **"
	echo "There is no config file present. Would you like to create one? (Y/n)"
	echo " "
	read -r store_config
	# Set to yes if answer is Y/y or empty
	if [[ -z ${store_config} ]]; then
		store_config="y" # Default to yes if no input is given
	elif [[ ${store_config} =~ ^[Yy]$ ]]; then
		store_config="y"
	elif [[ ${store_config} =~ ^[Nn]$ ]]; then
		store_config="n"
	else
		echo "Invalid input. Please enter y or n."
		exit 20
	fi
elif [[ -f ${CONFIG_FILE} ]]; then
	config_exists=true
	echo "** CONFIG FILE DETECTED **"
	echo "Config file already exists. You can edit it at ~/.config/pls/pls.conf"
	echo "If you want to create a new config file, please delete the existing one first."
	echo "If options are missing in the config, you will be asked to fill them in."
	echo " "
fi

# Add config file, if store_config is set to yes
if [[ ${store_config} == y ]]; then
	# Check if config directory exists and create if not
	if [[ ! -d ${CONFIG_PATH} ]]; then
		mkdir -p "${CONFIG_PATH}"
	fi

	# Create config file and add structure
	touch "${CONFIG_FILE}"

	# Set permissions to config folder and files
	chmod -R 700 "${CONFIG_PATH}"
fi

## MARK: URL
# Ask for Plex Server URL and store it in the config file
if [[ -z ${PLEX_SERVER_URL} ]]; then
	echo "** PLEX_SERVER_URL not set **"
	echo "Please enter your Plex Server URL or IP address (e.g., http://plex.local):"

	# Make sure input is not empty
	while true; do
		read -r plex_url

		# Validate URL format (basic validation)
		if [[ ! ${plex_url} =~ ^https?:// ]]; then
			echo "Invalid URL format. Please enter a valid Plex Server URL (e.g., http://plex.local):"
			continue
		fi

		# Remove trailing slash if present
		plex_url="${plex_url%/}"

		# Only store URL in config if $store_config is set to yes
		if [[ ${store_config} == y ]]; then
			echo "PLEX_SERVER_URL=${plex_url}" >>"${CONFIG_FILE}"
		fi

		# Break the loop if a valid URL is provided
		if [[ -n ${plex_url} ]]; then
			break
		else
			echo "URL cannot be empty. Please try again:"
		fi
	done
fi

## MARK: Port
# Ask for PMS Port, set default to 32400 if not provided
if [[ -z ${PLEX_SERVER_PORT} ]]; then
	echo "** PLEX_SERVER_PORT not set **"
	echo "Please enter your Plex Media Server Port (leave empty for default 32400):"

	# Validate port number if provided
	while true; do
		read -r plex_port
		if [[ -z ${plex_port} ]]; then
			plex_port=32400 # Default port
			echo "Using default port: ${plex_port}"
			break
		elif [[ ${plex_port} =~ ^[0-9]{1,5}$ && ${plex_port} -ge 1 && ${plex_port} -le 65535 ]]; then
			break # Valid port number
		else
			echo "Invalid port number. Please enter a valid port (1-65535) or leave empty for default 32400:"
			read -r plex_port
		fi
	done

	# Store port in config if $store_config is set to yes
	if [[ ${store_config} == y ]]; then
		echo "PLEX_SERVER_PORT=${plex_port}" >>"${CONFIG_FILE}"
	fi
fi

## MARK: Token
# Ask for Plex Token and store it in the config file
if [[ -z ${PLEX_TOKEN} ]]; then
	echo "** PLEX_TOKEN not set **"
	echo "Please enter your Plex Token (you can find it in your Plex account settings):"

	# Make sure input is not empty
	while true; do
		read -r plex_token

		# Store token in config if $store_config is set to yes
		if [[ ${store_config} == y ]]; then
			echo "PLEX_TOKEN=${plex_token}" >>"${CONFIG_FILE}"
		fi

		# Break the loop if a valid token is provided
		if [[ -n ${plex_token} ]]; then
			break
		else
			echo "Token cannot be empty. Please try again:"
		fi
	done
fi

## MARK: Main
# Source config file
source "${CONFIG_FILE}"

# Construct API URL
API_URL="${PLEX_SERVER_URL}:${PLEX_SERVER_PORT}"

# Fetch available libraries
echo "Fetching available libraries from Plex Media Server..."
libraries=$(curl --request GET \
	--insecure "${API_URL}/library/sections?X-Plex-Token=${PLEX_TOKEN}" \
	--header 'Accept: text/xml')

for i in $(seq 1 $(xmllint --xpath 'count(//Directory/Location)' ${libraries})); do
	xmllint --xpath "string((//Directory/Location)[$i]/concat(../@title,' | ',@id,' | ',@path))" input.xml
	echo
done

if [[ -z ${libraries} ]]; then
	echo "No libraries found or unable to connect to Plex Media Server."
	exit 1
fi

# Ask user to select library
echo "Wich library would you like to run Plex Library Scanner on?"
select library in ${libraries}; do
	if [[ -n ${library} ]]; then
		echo "You selected: ${library}"
		break
	else
		echo "Invalid selection. Please try again."
	fi
done

# Construct library key
library_key=$(echo "${library}" | grep -oP '(?<=key=")[^"]+')
# Construct API request URL
API_REQUEST_URL="${API_URL}/library/sections/${library_key}/refresh?X-Plex-Token=${PLEX_TOKEN}"

# Send request to Plex Media Server
echo "Triggering a scan for ${library}..."
response=$(curl -s -X POST "${API_REQUEST_URL}")
if [[ ${response} == *"<MediaContainer size=\"0\"/>"* ]]; then
	echo "Plex Library Scanner triggered successfully for ${library}."
	exit 0
elif [[ ${response} == *"<MediaContainer size=\"1\"/>"* ]]; then
	echo "Plex Library Scanner is already running for ${library}."
	exit 0
else
	echo "Failed to trigger Plex Library Scanner for ${library}. Response: ${response}"
	exit 10
fi
