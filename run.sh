#!/bin/bash

echo "Starting Invalidate CloudFront DNS Cache Script..."
echo "Distribution Id: $1"
echo "AWS Profile: $2"
echo "Generating parameters.json file..."

./generate.sh $1 > parameters.json

echo "File generated."

echo "Invoking lambda..."

aws lambda invoke --function-name purge-cloufront-distribution-cache-cli	\
	--cli-binary-format raw-in-base64-out --region us-east-2 --payload		\
	--profile "$2" file://parameters.json response.json				

results=$(tail response.json)

echo "Results: "$results

echo "Cleaning up..."

rm parameters.json
rm response.json
	
echo "Complete."