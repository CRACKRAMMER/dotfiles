ProjectName=$1
mkdir $ProjectName && cd $ProjectName
mkdir Include Source
touch Include/$ProjectName.h Source/{$ProjectName.cpp,main.cpp}

echo ''' CC = g++
LIB = -I ./Include
BUILD_DIR = Build
OUTFILE = $(notdir $(shell pwd))

CPP = $(wildcard Source/*.cpp)
OBJ = $(patsubst Source/%.cpp, $(BUILD_DIR)/%.o, $(CPP))

.PHONY: all mk_dir clean debug

all: mk_dir $(OUTFILE)

mk_dir:
	if [[ ! -d $(BUILD_DIR) ]]; then mkdir $(BUILD_DIR); fi

$(OUTFILE): $(OBJ)
	$(CC) $^ -o $@ $(DEBUG)

$(OBJ): $(BUILD_DIR)/%.o: Source/%.cpp
	$(CC) -c $(LIB) $^ -o $@ $(DEBUG)

debug:
	make clean
	make DEBUG=-g

clean:
	cd $(BUILD_DIR) && rm -f ./*
	if [[ -e $(OUTFILE) ]]; then rm $(OUTFILE); fi
''' > Makefile

cat << EOF > Include/$ProjectName.h
#ifndef __`echo $ProjectName | tr a-z A-Z`_H__
#define __`echo $ProjectName | tr a-z A-Z`_H__

#endif //__`echo $ProjectName | tr a-z A-Z`_H__
EOF

cat << EOF > Source/main.cpp
#include "$ProjectName.h"

int main(int argc, char *argv[]) {

    return 0;
}
EOF

cat << EOF > Source/$ProjectName.cpp
#include "$ProjectName.h"

EOF
