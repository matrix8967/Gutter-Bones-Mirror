#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

# curl https://api.controld.com/ip/nullroutecheck > ~/cd_status.log && curl https://api.controld.com/ip/info >> ~/cd_status.log && curl https://proxy-latency.controld.com:42069/info >> ~/cd_status.log && cat ~/cd_status.log | jq
jq -s . < <(
  {
    curl -s https://api.controld.com/ip/nullroutecheck
    curl -s https://api.controld.com/ip/info
    curl -s https://proxy-latency.controld.com:42069/info
  }
)
