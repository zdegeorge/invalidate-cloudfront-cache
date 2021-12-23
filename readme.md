# Invalidate CloudFront DNS Cache

This project will invoke a lambda function hosted on AWS using the [AWS CLI](https://docs.aws.amazon.com/cli/index.html) that will invalidate the DNS cache of an AWS CloudFront distribution. It's very helpful when deploying to CloudFront websites to have the updates you made to website propagate quickly.

## Requirements

This script is for Linux/MacOS operating systems. You also must have [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured with a profile for your AWS IAM credentials, as well as [oh my zsh](https://ohmyz.sh) installed for your terminal.

## Usage

1. Copy the contents of the project to a location somewhere in your home directory.
2. Make sure that you have a proper AWS CLI profile defined. You can define this profile by modifying the `config` file in the `~/.aws/` directory. It should look something like this:

```
[profile profile_name]
aws_access_key_id = XXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXX
region = us-east-2
output = json
```

3. Open your `~/.zshrc` file in the text editor of your choice and underneath where they define the alias's add the following code to the file, making sure to update the directory where you deployed the project to the function.

```
function purgedns() {
	clear
	script_location=<PUT PROJECT LOCATION HERE i.e. ~/Workspace/scripts/purgedns>
	echo "Input parameters: "$1" "$2
	if [ -z $1 ] || [ -z $2 ] || [ $1 = "help" ]
	then
		echo "Provide distribution id and AWS profile as arguments"
		echo "Example: purgedns ENXCCB4XH8NX6 profile_name"
	else
		current_location=$(pwd)
		cd $script_location
		./run.sh $1 $2
		cd $current_location
		unset current_location
		unset script_location
	fi
}
```

4. Source the `.zshrc` file and restart your terminal.
5. Open your AWS Console and navigate to the Lambda Console. Create a new function and name it `purge-cloufront-distribution-cache-cli`. You don't need to change any of the other settings. Copy the following code into the index.js file for your function:

```
const { CloudFront } = require('aws-sdk');

const cloudFront = new CloudFront({ apiVersion: 'latest' });

exports.handler = async (event, context) => {
	console.log('main');

	// Generate the Job ID for the Lambda action
	const jobId = Date.now().toString();

	console.log('jobId', jobId);

	// Retrieve the value of UserParameters from the Lambda action configuration in CodePipeline, in this case a URL which will be
	// health checked by this function.
	const DistributionId =
		event.distributionId;

	console.log('DistributionId', DistributionId);

	const cfRes = await cloudFront
		.createInvalidation({
			DistributionId,
			InvalidationBatch: {
				CallerReference: jobId,
				Paths: { Quantity: 1, Items: ['/*'] }
			}
		})
		.promise();

	console.log('cfRes', cfRes);

	if (cfRes.$response.error || !cfRes.$response.data) {
		const error =
			cfRes.$response.error ??
			new Error('No response data for CloudFront Invalidation.');

		return context.fail(error);
	}

    context.succeed(
		`Successfully invalidated cache for Distribution ID: ${DistributionId}`
	);
};
```

5. Deploy the Lambda function. Your welcome to test it if you would like. The test paramers should look like this, but you should pass a valid distribution id:

```
{
	"distributionId": "ENWCCB4BH8NK6"
}
```

6. Now you can use the command `purgedns <distributionId> <awsProfile>` from any location in your terminal, where you pass the distribution id, which can be found in the CloudFront Service Distribution Console, and the name of the AWS profile you defined in the `config` file in step 2. For example `purgedns ENWCCB4BH8NK6 my_profile`.

## To do's

1. Implement and document in Windows operating system.

## Author

Zach DeGeorge

zdegeorge@biggby.com

https://github.com/zdegeorge
