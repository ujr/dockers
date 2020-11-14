#!/bin/sh
# Wrapper around the AWK script of the same name,
# fixing parameters for ease of use.

FREE=10000  # adjust for your needs
COST=0.005  # adjust for your needs

AWK=/usr/bin/awk
LOC=$(dirname $0)

exec $AWK -f "$LOC/eval-du-log.awk" free=$FREE cost=$COST $*
