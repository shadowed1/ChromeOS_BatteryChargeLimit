#!/bin/bash
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)
echo ""
echo ""
echo ""
echo "             ${RED}████████████${RESET}             "
echo "         ${RED}████████████████████${RESET}         "
echo "       ${RED}████████████████████████${RESET}       "
echo "     ${GREEN}████████${RED}██████${RED}██████${GREEN}████████${RESET}     "
echo "   ${GREEN}████████${RED}████████${BLUE}██████${RED}████████${GREEN}████████${RESET}   "
echo "  ${GREEN}████████${RED}████████${BLUE}████████${RED}████████${GREEN}████████${RESET}  "
echo "  ${GREEN}████████${RED}████████${BLUE}████████${RED}████████${GREEN}████████${RESET}  "
echo "   ${GREEN}████████${RED}████████${BLUE}██████${RED}████████${GREEN}████████${RESET}   "
echo "     ${YELLOW}████████${GREEN}██████${GREEN}██████${YELLOW}████████${RESET}     "
echo "       ${YELLOW}████████████████████${RESET}       "
echo "         ${YELLOW}████████████████${RESET}         "
echo "             ${YELLOW}████████████${RESET}             "
echo ""
echo ""
echo ""
echo ""
echo "      ${BOLD}${GREEN}Chrome${RESET}${BOLD}${RED}OS${RESET}${BOLD}${YELLOW}_${RESET}${BOLD}${BLUE}PowerControl${RESET}"
echo ""
echo ""
echo ""
echo ""
echo "${CYAN}${BOLD}Downloading to: /home/chronos/ChromeOS_PowerControl_Installer.sh $RESET"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/ChromeOS_PowerControl_Installer.sh -o /home/chronos/ChromeOS_PowerControl_Installer.sh
echo "${GREEN}${BOLD}Download complete. Run the installer with VT-2 or (enable sudo in crosh)."
echo "Move it to an executable location or run these commands with VT-2:$RESET"
echo ""
echo "${BOLD}sudo mv /home/chronos/ChromeOS_PowerControl_Installer.sh /usr/local/bin"
echo ""
echo "sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh"
echo "$RESET"
echo ""
