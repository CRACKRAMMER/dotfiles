ProjectName=$1
shift

LIB=''

mkdir $ProjectName && cd $ProjectName
mkdir Include Source
touch Include/$ProjectName.h Source/{$ProjectName.cpp,main.cpp}

while [[ -n "$1" ]]; do
    LIB+="$1 "
    shift 
done

echo '''CC = g++
INC = -I ./Include
BUILD_DIR = Build
OUTFILE = $(notdir $(shell pwd))

CPP = $(wildcard Source/*.cpp)
OBJ = $(patsubst Source/%.cpp, $(BUILD_DIR)/%.o, $(CPP))

LIB = 

.PHONY: all mk_dir clean debug set_env

all: mk_dir $(OUTFILE)

mk_dir:
	if [[ ! -d $(BUILD_DIR) ]]; then mkdir $(BUILD_DIR); fi
set_env:
	sed -i -r "s/^LIB = .*$$/LIB = $(LIB)/" Makefile

$(OUTFILE): $(OBJ)
	$(CC) $^ -o $(BUILD_DIR)/$@ $(DEBUG) $(LIB)

$(OBJ): $(BUILD_DIR)/%.o: Source/%.cpp
	$(CC) -c $(INC) $^ -o $@ $(DEBUG)

debug:
	make clean
	make DEBUG=-g

clean:
	cd $(BUILD_DIR) && rm -f ./*
	if [[ -e $(OUTFILE) ]]; then rm $(OUTFILE); fi
''' > Makefile

sed -i -r "s/^LIB = .*$/LIB = $LIB/" Makefile

cat << EOF > Include/$ProjectName.h
#ifndef __`echo $ProjectName | tr a-z A-Z`_H__
#define __`echo $ProjectName | tr a-z A-Z`_H__

#endif //__`echo $ProjectName | tr a-z A-Z`_H__
EOF

cat << EOF > Source/main.cpp
#include "../Include/$ProjectName.h"

int main(int argc, char *argv[]) {

    return 0;
}
EOF

cat << EOF > Source/$ProjectName.cpp
#include "../Include/$ProjectName.h"

EOF
