#!/bin/bash

echo "Starting deployment..."
echo

echo "Adding all changes..."
git add .
if [ $? -ne 0 ]; then
    echo "Error: Failed to add files"
    exit 1
fi

echo
echo "Committing changes..."
git commit -m "update"
if [ $? -ne 0 ]; then
    echo "Error: Failed to commit changes"
    exit 1
fi

echo
echo "Pushing to remote repository..."
git push
if [ $? -ne 0 ]; then
    echo "Error: Failed to push changes"
    exit 1
fi

echo
echo "Deployment completed successfully!"
