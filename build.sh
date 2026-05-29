#!/usr/bin/env bash
#
# One-click build script for uboot-imx using Docker container.
# Supported platforms: x86_64, ARM64 (Apple Silicon Mac)
#

# Exit immediately if a command exits with a non-zero status
set -e

# Target configuration & Docker settings
TARGET_CONFIG="mx6ull_14x14_evk_qspi1_defconfig"
IMAGE_NAME="uboot-imx-builder"

# Colors for elegant CLI output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}${BOLD}==================================================${NC}"
echo -e "${BLUE}${BOLD}       uboot-imx Docker Compile Automation        ${NC}"
echo -e "${BLUE}${BOLD}==================================================${NC}"

# 1. Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo -e "${RED}${BOLD}Error:${NC} Docker is not installed or not in PATH. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}${BOLD}Error:${NC} Docker daemon is not running. Please start Docker Desktop first."
    exit 1
fi

# Get project root directory (where this script is located)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_DIR}"

# 2. Parse command line arguments
REBUILD_IMAGE=false
CLEAN_BUILD=true

show_help() {
    echo -e "Usage: $0 [options]"
    echo -e ""
    echo -e "Options:"
    echo -e "  -r, --rebuild    Force rebuild the Docker compiler image."
    echo -e "  -n, --no-clean   Skip 'make mrproper' step for incremental builds."
    echo -e "  -h, --help       Show this help message."
    echo -e ""
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--rebuild) REBUILD_IMAGE=true ;;
        -n|--no-clean) CLEAN_BUILD=false ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; show_help; exit 1 ;;
    esac
    shift
done

# 3. Build/Check Docker compile environment image
IMAGE_EXISTS=$(docker images -q "${IMAGE_NAME}" 2> /dev/null || true)

if [ -z "${IMAGE_EXISTS}" ] || [ "${REBUILD_IMAGE}" = true ]; then
    echo -e "${YELLOW}>> Building/Updating Docker compiler image [${IMAGE_NAME}]...${NC}"
    docker build -t "${IMAGE_NAME}" .
    echo -e "${GREEN}>> Docker compiler image is ready!${NC}\n"
else
    echo -e "${GREEN}>> Using existing Docker image [${IMAGE_NAME}].${NC}"
    echo -e "${BLUE}>> Hint: Run '$0 --rebuild' if you need to force update the image.${NC}\n"
fi

# 4. Construct the build command inside container
BUILD_COMMANDS=""
if [ "${CLEAN_BUILD}" = true ]; then
    echo -e "${YELLOW}>> Clean build enabled (running 'make mrproper')...${NC}"
    BUILD_COMMANDS="make mrproper && "
else
    echo -e "${YELLOW}>> Incremental build enabled (skipping deep clean)...${NC}"
fi

BUILD_COMMANDS="${BUILD_COMMANDS}make ${TARGET_CONFIG} && make -j\$(nproc)"

# 5. Run compile container
echo -e "${BLUE}>> Workspace Directory: ${PROJECT_DIR}${NC}"
echo -e "${BLUE}>> Target Configuration: ${TARGET_CONFIG}${NC}"
echo -e "${YELLOW}>> Starting compilation inside the container...${NC}"
echo -e "${BLUE}--------------------------------------------------${NC}"

# Run container with interactive, tty, and automatically clean container on exit
# Passes terminal signals to the build process gracefully
set +e
docker run --rm \
    -v "${PROJECT_DIR}":/workspace \
    -it \
    "${IMAGE_NAME}" \
    sh -c "${BUILD_COMMANDS}"
BUILD_STATUS=$?
set -e

echo -e "${BLUE}--------------------------------------------------${NC}"

# 6. Verify compilation results
if [ ${BUILD_STATUS} -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✔ Compilation completed successfully!${NC}"
    echo -e "${BLUE}>> Listing generated target binaries:${NC}"
    
    # Find compiled images/binaries in root
    TARGETS=$(find . -maxdepth 1 \( -name "u-boot*" -o -name "*.imx" -o -name "*.bin" \) ! -name "Dockerfile" ! -name "build.sh" 2>/dev/null || true)
    
    if [ -n "${TARGETS}" ]; then
        echo -e "${GREEN}${TARGETS}${NC}"
    else
        echo -e "${YELLOW}No specific target files found in the root directory. They might be in build subdirectories.${NC}"
    fi
else
    echo -e "${RED}${BOLD}✘ Compilation failed with exit code ${BUILD_STATUS}.${NC}"
    exit ${BUILD_STATUS}
fi
