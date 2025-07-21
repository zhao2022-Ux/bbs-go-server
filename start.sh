#!/bin/sh

export BBSGO_ENV=${BBSGO_ENV:-prod}
export PORT=${PORT:-8082}

./bbs-go
