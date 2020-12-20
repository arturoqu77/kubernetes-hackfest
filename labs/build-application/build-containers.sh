#
az acr build -t hackfest/data-api:1.0 -r $ACRNAME --no-logs -o json app/data-api
az acr build -t hackfest/flights-api:1.0 -r $ACRNAME --no-logs -o json app/flights-api
az acr build -t hackfest/quakes-api:1.0 -r $ACRNAME --no-logs -o json app/quakes-api
az acr build -t hackfest/weather-api:1.0 -r $ACRNAME --no-logs -o json app/weather-api
az acr build -t hackfest/service-tracker-ui:1.0 -r $ACRNAME --no-logs -o json app/service-tracker-ui

# to show size of an image in the ACR
az acr repository show-manifests -n $ACRNAME --repository hackfest/data-api --detail --query '[].{Size: imageSize, Tags: tags[0],Created: createdTime, Architecture: architecture, OS: os}' -o table