#!/bin/bash

# Màu sắc cho output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting Codebase Scan...${NC}"

# 1. Format Check
echo -e "\n${YELLOW}📦 Checking Code Formatting...${NC}"
if dart format --set-exit-if-changed .; then
    echo -e "${GREEN}✅ Formatting looks good!${NC}"
else
    echo -e "${RED}❌ Formatting issues found. Please run 'dart format .' to fix.${NC}"
    # Uncomment dòng dưới nếu muốn tự động fix luôn (thận trọng)
    # dart format .
fi

# 2. Analyze
echo -e "\n${YELLOW}🔍 Running Flutter Analyze...${NC}"
if flutter analyze; then
    echo -e "${GREEN}✅ No analysis issues found!${NC}"
else
    echo -e "${RED}❌ Analysis failed. Please fix the errors above.${NC}"
    exit 1
fi

# 3. Tests (Optional - uncomment if needed)
# echo -e "\n${YELLOW}🧪 Running Tests...${NC}"
# if flutter test; then
#     echo -e "${GREEN}✅ All tests passed!${NC}"
# else
#     echo -e "${RED}❌ Some tests failed.${NC}"
#     exit 1
# fi

echo -e "\n${GREEN}🎉 Codebase Scan Completed Successfully!${NC}"
