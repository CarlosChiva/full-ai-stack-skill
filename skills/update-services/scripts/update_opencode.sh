#!/bin/bash

docker pull ghcr.io/open-webui/open-webui:main
echo "downloaded last version"
docker stop open-webui
docker rm open-webui
echo "cleaned last container"
echo "Run last version of open-webui..."
docker run -d --network=host -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
echo "open-webui updated sucesfully."