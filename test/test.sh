#!/bin/bash
# Has to be executed from the root of the repository.
# Usually invoked by `make test`.
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'
BOLD='\033[1;39m'

RET=0
SQL_TEST_RET=0
MEM_LEAK_RET=0
CONFLICT_RET=0

#################################################
# Running SQL parser tests.
printf "\n${GREEN}Running SQL parser tests...${NC}\n"
bin/tests -f "test/queries/queries-good.sql" -f "test/queries/queries-bad.sql"
SQL_TEST_RET=$?

if [ $SQL_TEST_RET -eq 0 ]; then
	printf "${GREEN}SQL parser tests succeeded!${NC}\n"
else
	RET=1
	printf "${RED}SQL parser tests failed!${NC}\n"
fi

#################################################
# Running memory leak checks.
printf "\n${GREEN}Running memory leak checks...${NC}\n"
valgrind --leak-check=full --error-exitcode=200 --log-fd=3 \
  bin/tests -f "test/queries/queries-good.sql" -f "test/queries/queries-bad.sql" \
  3>&1>/dev/null;

MEM_LEAK_RET=$?
RET=1

if [ $MEM_LEAK_RET -eq 0 ]; then
  printf "${GREEN}Memory leak check succeeded!${NC}\n"
  MEM_LEAK_RET=0
  RET=0
elif [ $MEM_LEAK_RET -eq 200 ]; then
	printf "${RED}Memory leak check failed!${NC}\n"
elif [ $MEM_LEAK_RET -eq 127 ]; then
	printf "${RED}Memory leak check failed: command 'valgrind' not found!${NC}\n"
else
	printf "${RED}Memory leak check failes: error code ${MEM_LEAK_RET}!${NC}\n"
fi

#else
#  MEM_LEAK_RET=1
#  RET=1
#  printf "${RED}Memory leak check could not be executed!${NC}\n"
#fi

#################################################
# Checking if the grammar is conflict free.
printf "\n${GREEN}Checking for conflicts in the grammar...${NC}\n"
printf "${RED}"
make -C src/parser/ test >>/dev/null
CONFLICT_RET=$?

if [ $CONFLICT_RET -eq 0 ]; then
	printf "${GREEN}Conflict check succeeded!${NC}\n"
else
	RET=1
	printf "${RED}Conflict check failed!${NC}\n"
fi

# Print a summary of the test results.
printf "
----------------------------------
${BOLD}Summary:\n"
if [ $SQL_TEST_RET -eq 0 ]; then printf "SQL Tests:              ${GREEN}Success${BOLD}\n";
else							 printf "SQL Tests:              ${RED}Failure${BOLD}\n"; fi
if [ $MEM_LEAK_RET -eq 0 ]; then printf "Memory Leak Check:      ${GREEN}Success${BOLD}\n";
else							 printf "Memory Leak Check:      ${RED}Failure${BOLD}\n"; fi
if [ $CONFLICT_RET -eq 0 ]; then printf "Grammar Conflict Check: ${GREEN}Success${BOLD}\n";
else							 printf "Grammar Conflict Check: ${RED}Failure${BOLD}\n"; fi

if [ $RET -eq 0 ]; then printf "${GREEN}All tests passed!${NC}\n";
else                    printf "${RED}Some tests failed!${NC}\n"; fi
printf "${NC}----------------------------------\n"

exit $RET
