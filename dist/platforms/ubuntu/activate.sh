#!/usr/bin/env bash

function with_backoff {
  local max_attempts=${ATTEMPTS-5}
  local timeout=${TIMEOUT-5}
  local attempt=0
  local exitCode=0

  while [[ $attempt < $max_attempts ]]
  do
    "$@"
    exitCode=$?

    if [[ $exitCode == 0 ]]
    then
      break
    fi

    echo "Failure, exit code $exitCode! Retrying in $timeout seconds..." 1>&2
    sleep $timeout
    attempt=$(( attempt + 1 ))
    timeout=$(( timeout * 2 ))
  done

  if [[ $exitCode != 0 ]]
  then
    echo "Failed $max_attempts times, not trying again." 1>&2
  fi

  return $exitCode
}

if [[ -n "$UNITY_SERIAL" && -n "$UNITY_EMAIL" && -n "$UNITY_PASSWORD" ]]; then
  #
  # SERIAL LICENSE MODE
  #
  # This will activate unity, using the activating process.
  #
  echo "Requesting activation"

  # Loop the unity-editor call until the license is activated with exponential backoff and a maximum of 5 retries
  retry_count=0

  # Initialize delay to 15 seconds
  delay=15

  # Loop until UNITY_EXIT_CODE is 0 or retry count reaches 5
  while [[ $retry_count -lt 5 ]]
  do
    # Activate license
    unity-editor \
      -logFile /dev/stdout \
      -quit \
      -serial "$UNITY_SERIAL" \
      -username "$UNITY_EMAIL" \
      -password "$UNITY_PASSWORD" \
      -projectPath "/BlankProject"

    # Store the exit code from the verify command
    UNITY_EXIT_CODE=$?

    # Check if UNITY_EXIT_CODE is 0
    if [[ $UNITY_EXIT_CODE -eq 0 ]]
    then
      echo "Activation successful"
      break
    else
      # Increment retry count
      ((retry_count++))

      echo "::warning ::Activation failed, attempting retry #$retry_count"
      echo "Activation failed, retrying in $delay seconds..."
      sleep $delay

      # Double the delay for the next iteration
      delay=$((delay * 2))
    fi
  done

  if [[ $retry_count -eq 5 ]]
  then
    echo "Activation failed after 5 retries"
  fi

elif [[ -n "$UNITY_LICENSING_SERVER" ]]; then
  #
  # Custom Unity License Server
  #
  echo "Adding licensing server config"

  with_backoff /opt/unity/Editor/Data/Resources/Licensing/Client/Unity.Licensing.Client --acquire-floating
  UNITY_EXIT_CODE=$?
else
  #
  # NO LICENSE ACTIVATION STRATEGY MATCHED
  #
  # This will exit since no activation strategies could be matched.
  #
  echo "License activation strategy could not be determined."
  echo ""
  echo "Visit https://game.ci/docs/github/activation for more"
  echo "details on how to set up one of the possible activation strategies."

  echo "::error ::No valid license activation strategy could be determined. Make sure to provide UNITY_EMAIL, UNITY_PASSWORD, and either a UNITY_SERIAL \
or UNITY_LICENSE. Otherwise please use UNITY_LICENSING_SERVER."
  # Immediately exit as no UNITY_EXIT_CODE can be derived.
  exit 1;

fi

#
# Display information about the result
#
if [ $UNITY_EXIT_CODE -eq 0 ]; then
  # Activation was a success
  echo "Activation complete."
else
  # Activation failed so exit with the code from the license verification step
  echo "Unclassified error occured while trying to activate license."
  echo "Exit code was: $UNITY_EXIT_CODE"
  echo "::error ::There was an error while trying to activate the Unity license."
  exit $UNITY_EXIT_CODE
fi
