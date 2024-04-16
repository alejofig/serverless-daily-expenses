#Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_route53_zone" "zone" {
  name = "uniandes-sports.com"  # Reemplaza con el nombre de tu zona existente
}


resource "aws_ses_domain_identity" "primary" {
  domain = data.aws_route53_zone.zone.name
}


resource "aws_route53_record" "ses_verif" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.primary.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.primary.verification_token]
}

resource "aws_ses_domain_identity_verification" "ses_verif" {
  domain = aws_ses_domain_identity.primary.id

  depends_on = [aws_route53_record.ses_verif]
}

resource "aws_route53_record" "email_bucket" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = data.aws_route53_zone.zone.name
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}

resource "aws_s3_bucket" "email" {
  bucket = "uniandes-emails-transacions" ## Acá pones tu bucket

}


resource "aws_s3_bucket_policy" "email" {
  bucket = aws_s3_bucket.email.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSESPuts",
      "Effect": "Allow",
      "Principal": {
        "Service": "ses.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.email.arn}/email/*",
      "Condition": {
        "StringEquals": {
        "aws:Referer": "${data.aws_caller_identity.current.account_id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_ses_receipt_rule_set" "primary" {
  rule_set_name = "primary"
}

resource "aws_ses_active_receipt_rule_set" "primary" {
  rule_set_name = aws_ses_receipt_rule_set.primary.rule_set_name
}

resource "aws_ses_receipt_rule" "email" {
  name          = "receive-email-uniandes-rule" ## Acá pones el nombre de la regla
  rule_set_name = aws_ses_receipt_rule_set.primary.rule_set_name
  recipients    = ["transactions@uniandes-sports.com"] ## Acá pones tu correo
  enabled       = true
  scan_enabled  = false

  s3_action {
    position          = 1
    bucket_name       = aws_s3_bucket.email.bucket
    object_key_prefix = "email/"
  }
}


## Lambda 

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role-uniandes-transactions"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
  inline_policy {
    name = "lambda_logs_policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }]
    })
  }
}

resource "aws_lambda_function" "transform-email" {
  function_name = "transform_email_bedrock"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = "344488016360.dkr.ecr.us-west-2.amazonaws.com/transactions-uniandes-mail:latest"  # Cambia la URI de la imagen con la tuya
  
  environment {
    variables = {
        SPREADSHEET_NAME="Cuentas Alejofig"
        WORKSHEET_NAME = "Uniandes"
    }
  }
    tracing_config {
    mode = "Active"
  }
  timeout = 600
}

resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transform-email.function_name
  principal     = "s3.amazonaws.com"

  source_arn = aws_s3_bucket.email.arn
}

resource "aws_s3_bucket_notification" "lambda_invoke" {
  bucket = aws_s3_bucket.email.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.transform-email.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "email/"
  }
}




resource "aws_iam_policy" "bedrock_invoke_policy" {
  name        = "bedrock-invoke-policy"
  description = "Policy for granting invoke permissions to bedrock"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Action    = [
        "bedrock:InvokeModel"
      ],
      Resource  = [
        "*"
        ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_invoke_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.bedrock_invoke_policy.arn
}

resource "aws_iam_policy" "s3_read_policy" {
  name        = "s3-read-policy"
  description = "Policy for granting read access to S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Action    = [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      Resource  = [
        "${aws_s3_bucket.email.arn}",
        "${aws_s3_bucket.email.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}