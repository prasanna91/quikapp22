    echo "🔍 Validating Apple API signing environment..."

    # Check for the .p8 API key file at the expected path
    if [[ ! -f "$APP_STORE_CONNECT_API_KEY_PATH" ]]; then
      echo "❌ .p8 file not found: $APP_STORE_CONNECT_API_KEY_PATH"
      exit 1
    fi

    for var in APP_STORE_CONNECT_KEY_IDENTIFIER APP_STORE_CONNECT_ISSUER_ID APPLE_TEAM_ID BUNDLE_ID PROFILE_TYPE; do
      if [[ -z "${!var}" ]]; then
        echo "❌ Missing required env var: $var"
        exit 1
      else
        echo "✅ $var is set: ${!var}"
      fi
    done

    #IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c 'Apple Distribution')

    #if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
    #echo "❌ No valid Apple Distribution signing identities found in keychain"
    #exit 1
    #else
    #echo "✅ Found $IDENTITY_COUNT valid Apple Distribution identity(ies)"
    #fi

    echo "✅ Apple API signing setup appears valid"
