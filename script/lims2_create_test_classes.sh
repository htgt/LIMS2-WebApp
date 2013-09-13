#!/bin/bash
# lims2_create_test_classes.sh
# Lars G. Erlandsen, 'Viking'
#

for i in `(cd ../../lib && find . -type f -name '*.pm' -print) | egrep -v '^\.$'`
do
    echo "========================================================================================"
    PACKAGE_NAME="`echo ${i} | sed 's,^./,,'`"
    PACKAGE_DIR="`dirname ${i} | sed 's,^./,,'`"
    PACKAGE_MODULENAME="`echo ${i} | sed -e 's,^./,,' -e 's/\.pm$//' -e 's,/,::,g'`"
    TESTPACKAGE="`echo ${PACKAGE_NAME} | sed 's,^LIMS2/,LIMS2/t/,'`"
    TESTPACKAGE_DIR="`dirname ${TESTPACKAGE}`"
    TESTPACKAGE_MODULENAME="`echo ${TESTPACKAGE} | sed -e 's/\.pm$//' -e 's,/,::,g'`"
    TESTFILENAME="`echo ${PACKAGE_NAME} | sed -e 's/\.pm$//' -e 's,/,_,g' -e 's/^/10_/' -e 's/$/.t/'`"
    LIB_TEST_DIR="`echo ${PACKAGE_DIR} | sed 's/\w\w*/../g' | sed 's,$,/lib,'`"
    LIB_DIR="`echo ${PACKAGE_DIR} | sed 's/\w\w*/../g' | sed 's,$,/../lib,'`"

    echo "Package to test (PACKAGE_NAME) = ${PACKAGE_NAME}"
    echo "Package directory (PACKAGE_DIR) = ${PACKAGE_DIR}"
    echo "Package module name (PACKAGE_MODULENAME) = ${PACKAGE_MODULENAME}"
    echo "Test package (TESTPACKAGE) = ${TESTPACKAGE}"
    echo "Test package directory (TESTPACKAGE_DIR) = ${TESTPACKAGE_DIR}"
    echo "Test package module name (TESTPACKAGE_MODULENAME) = ${TESTPACKAGE_MODULENAME}"
    echo "Test file name (TESTFILENAME) = ${TESTFILENAME}"
    echo "Lib test directory path (LIB_TEST_DIR) = ${LIB_TEST_DIR}"
    echo "Lib directory path (LIB_DIR) = ${LIB_DIR}"
    echo "========================================================================================"
    echo "mkdir -p ../${PACKAGE_DIR}"
    mkdir -p ../${PACKAGE_DIR}
    echo "mkdir -p ../lib/${TESTPACKAGE_DIR}"
    mkdir -p ../lib/${TESTPACKAGE_DIR}
    echo "========================================================================================"
    cat ./skeleton_package.txt | sed -e "s,{PACKAGE_NAME},${PACKAGE_NAME},g" -e "s,{PACKAGE_DIR},${PACKAGE_DIR},g" -e "s,{PACKAGE_MODULENAME},${PACKAGE_MODULENAME},g" -e "s,{TESTPACKAGE},${TESTPACKAGE},g" -e "s,{TESTPACKAGE_DIR},${TESTPACKAGE_DIR},g" -e "s,{TESTPACKAGE_MODULENAME},${TESTPACKAGE_MODULENAME},g" -e "s,{TESTFILENAME},${TESTFILENAME},g" -e "s,{LIB_TEST_DIR},${LIB_TEST_DIR},g" -e "s,{LIB_DIR},${LIB_DIR},g"
    echo "Generating output file '${TESTPACKAGE}'"
    #cat ./skeleton_package.txt | sed -e "s,{PACKAGE_NAME},${PACKAGE_NAME},g" -e "s,{PACKAGE_DIR},${PACKAGE_DIR},g" -e "s,{PACKAGE_MODULENAME},${PACKAGE_MODULENAME},g" -e "s,{TESTPACKAGE},${TESTPACKAGE},g" -e "s,{TESTPACKAGE_DIR},${TESTPACKAGE_DIR},g" -e "s,{TESTPACKAGE_MODULENAME},${TESTPACKAGE_MODULENAME},g" -e "s,{TESTFILENAME},${TESTFILENAME},g" -e "s,{LIB_TEST_DIR},${LIB_TEST_DIR},g" -e "s,{LIB_DIR},${LIB_DIR},g" > ${TESTPACKAGE}
    echo "========================================================================================"
    cat ./skeleton_t_file.txt | sed -e "s,{PACKAGE_NAME},${PACKAGE_NAME},g" -e "s,{PACKAGE_DIR},${PACKAGE_DIR},g" -e "s,{PACKAGE_MODULENAME},${PACKAGE_MODULENAME},g" -e "s,{TESTPACKAGE},${TESTPACKAGE},g" -e "s,{TESTPACKAGE_DIR},${TESTPACKAGE_DIR},g" -e "s,{TESTPACKAGE_MODULENAME},${TESTPACKAGE_MODULENAME},g" -e "s,{TESTFILENAME},${TESTFILENAME},g" -e "s,{LIB_TEST_DIR},${LIB_TEST_DIR},g" -e "s,{LIB_DIR},${LIB_DIR},g"
    echo "Generating output file '../${PACKAGE_DIR}/${TESTFILENAME}'"
    #cat ./skeleton_t_file.txt | sed -e "s,{PACKAGE_NAME},${PACKAGE_NAME},g" -e "s,{PACKAGE_DIR},${PACKAGE_DIR},g" -e "s,{PACKAGE_MODULENAME},${PACKAGE_MODULENAME},g" -e "s,{TESTPACKAGE},${TESTPACKAGE},g" -e "s,{TESTPACKAGE_DIR},${TESTPACKAGE_DIR},g" -e "s,{TESTPACKAGE_MODULENAME},${TESTPACKAGE_MODULENAME},g" -e "s,{TESTFILENAME},${TESTFILENAME},g" -e "s,{LIB_TEST_DIR},${LIB_TEST_DIR},g" -e "s,{LIB_DIR},${LIB_DIR},g" > ../${PACKAGE_DIR}/${TESTFILENAME}
    echo "========================================================================================"
done

#for i in `find . -type d -print | egrep -v '^\.$' | sed 's/^..//'`
#do
#    echo "Processing ${i}/Test.pm ..."
#    BASE_PACKAGE="`echo ${i} | sed 's/\//::/g'`"
#    PACKAGE_NAME="${BASE_PACKAGE}::Test"
#    PARENT_DIR="`dirname ${i}`"
#    if [ "${PARENT_DIR}" = "." ]
#    then
#	PARENT_PACKAGE_NAME=""
#	REQUIRE_PARENT=""
#	LIB_TEST_DIR="../lib"
#	LIB_DIR="../../lib"
#    else
#	PARENT_PACKAGE_NAME="`dirname ${i} | sed 's/\//::/g' | sed 's/$/::Test/'`"
#	REQUIRE_PARENT="require ${PARENT_PACKAGE_NAME};"
#	LIB_TEST_DIR="`echo ${i} | sed 's/\w\w*/../g' | sed 's/$/\/lib/'`"
#	LIB_DIR="`echo ${i} | sed 's/\w\w*/../g' | sed 's/$/\/..\/lib/'`"
#    fi
#    TESTFILENAME="`echo ${i} | sed -e 's/\//_/g' -e 's/^/10_/' -e 's/$/.t/'`"
#    echo "Base package = ${BASE_PACKAGE}"
#    echo "Package name = ${PACKAGE_NAME}"
#    echo "Parent directory = ${PARENT_DIR}"
#    echo "Library directory = ${LIB_DIR}"
#    echo "Parent package name = ${PARENT_PACKAGE_NAME}"
#    echo "Testfile name = ${TESTFILENAME}"
#    echo "========================================================================================"
#    #cat ./skeleton_package.txt | sed -e "s/{BASE_PACKAGE}/${BASE_PACKAGE}/g" -e "s/{PACKAGE_NAME}/${PACKAGE_NAME}/g" -e "s/{TESTFILENAME}/${TESTFILENAME}/g" -e "s/{REQUIRE_PARENT}/${REQUIRE_PARENT}/g"
#    cat ./skeleton_package.txt | sed -e "s/{BASE_PACKAGE}/${BASE_PACKAGE}/g" -e "s/{PACKAGE_NAME}/${PACKAGE_NAME}/g" -e "s/{TESTFILENAME}/${TESTFILENAME}/g" -e "s/{REQUIRE_PARENT}/${REQUIRE_PARENT}/g" > ${i}/Test.pm
#    echo "========================================================================================"
#    echo "mkdir -p ../${i}"
#    #mkdir -p ../${i}
#    echo "========================================================================================"
#    #cat ./skeleton_t_file.txt | sed -e "s/{BASE_PACKAGE}/${BASE_PACKAGE}/g" -e "s/{PACKAGE_NAME}/${PACKAGE_NAME}/g" -e "s/{TESTFILENAME}/${TESTFILENAME}/g" -e "s,{LIB_TEST_DIR},${LIB_TEST_DIR},g" -e "s,{LIB_DIR},${LIB_DIR},g"
#    cat ./skeleton_t_file.txt | sed -e "s/{BASE_PACKAGE}/${BASE_PACKAGE}/g" -e "s/{PACKAGE_NAME}/${PACKAGE_NAME}/g" -e "s/{TESTFILENAME}/${TESTFILENAME}/g" -e "s,{LIB_TEST_DIR},${LIB_TEST_DIR},g" -e "s,{LIB_DIR},${LIB_DIR},g" > ../${i}/${TESTFILENAME}
#    echo "========================================================================================"
#
#done


