{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}

# What is a Trust Policy?

A trust policy defines **who is allowed to assume an IAM role**.

Example:

Lambda Service

↓

Requests Temporary Credentials

↓

AWS STS

↓

IAM Role

↓

Temporary Credentials Issued

↓

Lambda Uses Permissions
