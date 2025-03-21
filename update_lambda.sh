#!/bin/bash

BACKEND_DIR="./backend"
CHANGED=0

echo "🚀 Starting Lambda ZIP process..."
echo ""

for FUNCTION_DIR in "$BACKEND_DIR"/*; do
    if [ -d "$FUNCTION_DIR" ]; then
        FUNCTION_NAME=$(basename "$FUNCTION_DIR")
        if [ "$FUNCTION_NAME" = "tests" ]; then
            continue
        fi

        if [ "$FUNCTION_NAME" = "price_prediction" ]; then
            continue
        fi

        ZIP_FILE="$FUNCTION_DIR/lambda.zip"
        TEMP_CHECKSUM_FILE="$FUNCTION_DIR/.checksum"

        NEW_CHECKSUM=$(md5sum "$FUNCTION_DIR"/handler.py "$FUNCTION_DIR"/helpers.py 2>/dev/null | md5sum | awk '{print $1}')


        if [ ! -f "$TEMP_CHECKSUM_FILE" ]; then
            touch "$TEMP_CHECKSUM_FILE"
        fi

        OLD_CHECKSUM=$(cat "$TEMP_CHECKSUM_FILE")

        if [ "$NEW_CHECKSUM" != "$OLD_CHECKSUM" ]; then
            echo "📦 Changes detected for $FUNCTION_NAME. Updating the zip"
            echo "📦 Zipping function: $FUNCTION_NAME..."
            cd "$FUNCTION_DIR" || exit
            if [ "$FUNCTION_NAME" = "top_school_area" ]; then
                zip -r -X lambda.zip handler.py helpers.py ../general_helpers.py schools.csv > /dev/null
            else
                zip -r -X lambda.zip handler.py helpers.py ../general_helpers.py > /dev/null
            fi
            cd - > /dev/null
            # stores the new CHECKSUM FILE
            echo "$NEW_CHECKSUM" | tee "$TEMP_CHECKSUM_FILE" > /dev/null
            echo "✅ Created: $ZIP_FILE"
            CHANGED=1
        else 
            echo "🐼 No change detected for $FUNCTION_NAME, skipping da zip!"
        fi
    fi
done

if [ "$CHANGED" -eq 1 ]; then
    echo "Updating variable names in variable.tf..."
    python3 update_variables.py

    echo "🎉 Ready for deployment! Run terraform apply only if you ready gang"
else
    echo "🐻 No lambda functions updated, skipping terraform apply"
fi
