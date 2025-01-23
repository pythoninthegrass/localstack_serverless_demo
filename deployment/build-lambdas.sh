#!/usr/bin/env bash

# shellcheck disable=SC2086,SC2164

BASE_DIR="lambdas"
LAMBDA_DIRS=("presign" "list" "resize")
if [ "$DEPLOY_TARGET" = "aws" ]; then
    PIP_FLAGS="--platform manylinux2014_x86_64 --only-binary=:all:"
else
    PIP_FLAGS=""
fi

for dir in "${LAMBDA_DIRS[@]}"; do
    LAMBDA_PATH="${BASE_DIR}/${dir}"
    echo "Building Lambda function in $LAMBDA_PATH..."
    if [ -d "$LAMBDA_PATH" ]; then
        (cd "$LAMBDA_PATH" && rm -f lambda.zip && zip lambda.zip handler.py)

        # Special handling for resize lambda that has dependencies
        if [ "$dir" = "resize" ] && [ -f "${LAMBDA_PATH}/requirements.txt" ]; then
            echo "Installing dependencies for resize lambda..."
            (
                cd "$LAMBDA_PATH"
                rm -rf package
                mkdir -p package
                if [ -s requirements.txt ]; then
                    pip install -r requirements.txt -t package $PIP_FLAGS
                    cd package
                    zip -r ../lambda.zip .
                else
                    echo "Warning: requirements.txt is empty"
                fi
            )
        fi
    else
        echo "Directory $LAMBDA_PATH not found!"
        exit 1
    fi
done
