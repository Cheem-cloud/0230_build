#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========== CheemHang Setup ==========${NC}"
echo

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed.${NC}"
    exit 1
fi

# Check if Swift Package Manager is available
if ! command -v swift &> /dev/null; then
    echo -e "${RED}Error: Swift is not available.${NC}"
    exit 1
fi

# Check for GoogleService-Info.plist
if [ ! -f "GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}Warning: GoogleService-Info.plist is missing.${NC}"
    echo -e "You need to add GoogleService-Info.plist from the Firebase Console."
    echo -e "Please see GoogleService-Info.plist.example for reference."
    echo
fi

# Resolve dependencies
echo -e "${GREEN}Resolving Swift Package dependencies...${NC}"
swift package resolve

# Generate Xcode project
echo -e "${GREEN}Generating Xcode project...${NC}"
swift package generate-xcodeproj

echo
echo -e "${GREEN}Setup completed!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open the generated Xcode project: xed ."
echo "2. Configure your Firebase by adding GoogleService-Info.plist"
echo "3. Update Info.plist with your Google Client ID"
echo "4. Build and run the app!"
echo 