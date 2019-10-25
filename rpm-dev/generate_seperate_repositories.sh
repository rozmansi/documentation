#!/bin/sh

REPO_DIR=${HOME}/repo-SPEC

for SPEC in $(ls *.spec)
do
	REPO_NAME=$(basename ${SPEC} .spec)
	echo ${REPO_NAME}
 	mkdir -p ${REPO_DIR}/${REPO_NAME}/SPECS
	mkdir -p ${REPO_DIR}/${REPO_NAME}/SOURCES
	cp ${REPO_NAME}.spec ${REPO_DIR}/${REPO_NAME}/SPECS
	cp ${REPO_NAME}* ${REPO_DIR}/${REPO_NAME}/SOURCES
	cp minisign-8466FFE127BCDC82.pub ${REPO_DIR}/${REPO_NAME}/SOURCES 
	rm ${REPO_DIR}/${REPO_NAME}/SOURCES/*.spec
	(
		cd ${REPO_DIR}/${REPO_NAME}
		if [ ! -d ".git" ]
		then
			git init
			git remote add origin git@git.tuxed.net:rpm/${REPO_NAME}
		fi
		git add .
		git commit -a -m 'add development spec'
		git push origin master
	)
done
