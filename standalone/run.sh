#!/bin/bash

/opt/hbase/bin/start-hbase.sh
tail -f /opt/hbase/logs/*
