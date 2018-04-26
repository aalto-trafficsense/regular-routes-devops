#!/bin/bash

echo "This migration script should be executed on a regularroutes server."
echo "It is assumed that the server has been migrated and is running."
echo ""

echo "Restoring database contents."
echo "Will show some errors about not being able to drop & create extension postgis etc., which should already exist in the new db."
pg_restore --clean -h 127.0.0.1 -U regularroutes -d regularroutes ~/regularroutes_dump_full.tar
